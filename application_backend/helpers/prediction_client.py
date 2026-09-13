##################################################################################
# Copyright (c) 2026 Matthew Thomas Beck                                         #
#                                                                                #
# Licensed under the Creative Commons Attribution-NonCommercial 4.0              #
# International (CC BY-NC 4.0). Personal and educational use is permitted.       #
# Commercial use by companies or for-profit entities is prohibited.              #
##################################################################################





############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for predictor client messages
import os # import os for PREDICTOR_BASE_URL / callback env vars
import time # import time for wait/poll loops
from datetime import datetime, timezone # import datetime for Tiger prediction timestamps
from pathlib import Path # import Path for cwd-independent .env loading
from typing import Any, Dict, List, Optional # import typing helpers

##### import third-party libraries #####

import requests # import requests for HTTP calls to predictor_backend
from dotenv import load_dotenv # import dotenv to load predictor env vars

##### import local modules #####

from helpers.auth0 import get_m2m_token # import Auth0 M2M token helper for predictor auth
from helpers import callback_store # import in-memory callback result store

##### load environment #####

load_dotenv(Path(__file__).resolve().parent.parent / ".env") # load application_backend/.env





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger

PREDICTOR_DATE_FORMAT = "YYYY-MM-DD" # predictor date_utils day format (not strftime)





##################################################
############### PREDICTOR URL HELPERS ############
##################################################


########## PREDICTOR BASE URL ##########

def _predictor_base_url(): # function to read PREDICTOR_BASE_URL and strip trailing slash

    base = os.getenv("PREDICTOR_BASE_URL", "").rstrip("/") # configured Tailscale base
    if not base: # URL required
        raise ValueError("PREDICTOR_BASE_URL is not set") # fail fast
    return base # normalized base URL


########## PREDICT ENDPOINT ##########

def _predict_endpoint(): # function to resolve full /api/v1/predict URL from base or partial paths

    base = _predictor_base_url() # read base
    if base.endswith("/api/v1/predict") or base.endswith("/predict"): # already a predict URL
        return base # use as-is
    if base.endswith("/api/v1"): # API root only
        return f"{base}/predict" # append predict
    return f"{base}/api/v1/predict" # default full path


########## DEFAULT CALLBACK URL ##########

def _default_callback_url(): # function to build predictor→EC2 callback URL from CALLBACK_BASE_URL

    callback_base = os.getenv("CALLBACK_BASE_URL", "").rstrip("/") # must be Tailscale-reachable EC2 URL
    if not callback_base: # required for async results
        raise ValueError(
            "CALLBACK_BASE_URL is not set - use the EC2 Tailscale IP/hostname "
            "(e.g. http://100.x.y.z:8080), not localhost"
        ) # fail fast
    return f"{callback_base}/callback/solana" # root callback path mounted in main.py





##################################################
############### PAYLOAD SHAPING ##################
##################################################


########## BAR TIME TO X ##########

def _bar_time_to_x(value): # function to turn Tiger/ISO timestamps into YYYY-MM-DD x labels

    if isinstance(value, datetime): # datetime from Tiger or parser
        return value.astimezone(timezone.utc).strftime("%Y-%m-%d") # UTC calendar day
    text = str(value) # string / ISO
    if "T" in text: # ISO datetime
        return text.split("T", 1)[0] # date portion
    return text[:10] # already YYYY-MM-DD-ish


########## PARSE PREDICTION TIME ##########

def _parse_prediction_time(value): # function to parse predictor x labels into UTC datetimes for Tiger

    if isinstance(value, datetime): # already datetime
        if value.tzinfo is None: # naive
            return value.replace(tzinfo=timezone.utc) # assume UTC
        return value.astimezone(timezone.utc) # normalize

    text = str(value).strip() # string label
    if "T" in text: # ISO
        dt = datetime.fromisoformat(text.replace("Z", "+00:00")) # parse ISO
        if dt.tzinfo is None: # naive ISO
            return dt.replace(tzinfo=timezone.utc) # assume UTC
        return dt.astimezone(timezone.utc) # normalize

    dt = datetime.strptime(text[:10], "%Y-%m-%d") # day label
    return dt.replace(tzinfo=timezone.utc) # midnight UTC


########## BUILD PREDICTION PAYLOAD ##########

def build_prediction_payload(ohlcv_data, num_predictions, callback_url=None): # function to shape Tiger OHLCV into predictor JSON

    series = (ohlcv_data or {}).get("series") or [] # candle list
    points = [] # {x,y} close series
    for bar in series: # each OHLCV row
        close = bar.get("close") # predicted target
        if close is None: # skip incomplete
            continue # next bar
        points.append(
            {
                "x": _bar_time_to_x(bar.get("time")),
                "y": float(close),
            }
        ) # one close point

    if len(points) < 19: # predictor needs SEQUENCE_LENGTH(14) + max horizon(5)
        raise ValueError(
            f"Need at least 19 OHLCV closes for predictor, got {len(points)}"
        ) # fail before enqueue

    num_predictions = max(1, min(int(num_predictions), 5)) # predictor hard cap

    payload: Dict[str, Any] = {
        "asset": "SOL",
        "numPredictions": num_predictions,
        "xAxis": {"format": PREDICTOR_DATE_FORMAT},
        "yAxis": {"label": "close"},
        "timeSeries": [
            {
                "name": "SOL-USD",
                "data": points,
            }
        ],
    } # TSP-shaped body
    if callback_url: # optional async callback
        payload["callback_url"] = callback_url # attach callback URL
    return payload # shaped JSON for predictor


########## CALLBACK TO PREDICTION ROWS ##########

def callback_to_prediction_rows(callback_payload, num_predictions=5): # function to extract future closes for sol_predictions

    if not callback_payload: # empty
        return [] # nothing to upsert

    predictions = callback_payload.get("predictions") or [] # per-series results
    if not predictions: # no series
        return [] # nothing

    series = predictions[0] # SOL-USD (only series we send)
    data = series.get("data") or [] # fitted history + future tail
    n = max(1, min(int(num_predictions), 5)) # horizon used
    future_points = data[-n:] if len(data) >= n else data # last N = future steps

    rows: List[Dict[str, Any]] = [] # Tiger-ready rows
    for point in future_points: # each forecast day
        rows.append(
            {
                "time": _parse_prediction_time(point["x"]),
                "predicted_close": float(point["y"]),
                "model_version": "bigru-attn-v1",
            }
        ) # one forecast row

    return rows # ready for tiger_db.upsert_predictions


########## CALLBACK TO FRONTEND SERIES ##########

def callback_to_frontend_predictions(callback_payload, num_predictions=5): # function to build frontend predictions blob from callback

    rows = callback_to_prediction_rows(callback_payload, num_predictions=num_predictions) # parse
    series = [
        {
            "time": row["time"].isoformat(),
            "predicted_close": row["predicted_close"],
            "model_version": row.get("model_version", "bigru-attn-v1"),
        }
        for row in rows
    ] # JSON-ready
    return {"asset": "SOL", "series": series} # frontend shape





##################################################
############### PREDICTION CLIENT ################
##################################################


########## SEND TIMESERIES TO PREDICTOR ##########

def send_timeseries_to_predictor( # function to POST SOL timeseries to predictor_backend with Auth0 M2M Bearer token
        ohlcv_data,
        num_predictions=5,
        callback_url=None
):

    if callback_url is None: # default callback from env
        callback_url = _default_callback_url() # Tailscale EC2 callback

    token = get_m2m_token() # Auth0 M2M Bearer for predictor
    payload = build_prediction_payload(ohlcv_data, num_predictions, callback_url) # build body
    endpoint = _predict_endpoint() # resolve predict URL

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
        "X-Metric-Name": "solana",
        "X-Callback-URL": callback_url,
        "X-Auth0-Audience": os.getenv("AUTH0_PREDICTOR_AUDIENCE", ""),
    } # predictor request headers

    logger.info(
        "Sending SOL timeseries to predictor at %s (points=%s num_predictions=%s callback=%s)",
        endpoint,
        len(payload["timeSeries"][0]["data"]),
        payload["numPredictions"],
        callback_url,
    ) # log outbound request

    response = requests.post(
        endpoint,
        json=payload,
        headers=headers,
        params={"callback_url": callback_url},
        timeout=30,
    ) # POST timeseries to predictor

    if response.status_code not in (200, 202): # reject unexpected statuses
        logger.error(
            "Predictor rejected request (%s): %s",
            response.status_code,
            response.text,
        ) # log error body
        response.raise_for_status() # surface HTTP error

    return response.json() if response.content else {"status": "accepted"} # ack / task_id JSON


########## WAIT FOR PREDICTIONS ##########

def wait_for_predictions( # function to block until /callback/solana stores completed predictions
        task_id=None,
        timeout_seconds=600,
        poll_interval_seconds=2.0
):

    logger.info(
        "Waiting for predictor callback (task_id=%s timeout=%ss)",
        task_id,
        timeout_seconds,
    ) # log wait start

    deadline = time.time() + timeout_seconds # absolute timeout
    while time.time() < deadline: # poll in-memory store
        result = callback_store.get_pending_prediction_result() # filled by callback route
        if result is not None: # callback arrived
            logger.info(
                "Predictor callback received (keys=%s hasPredictions=%s)",
                list(result.keys()),
                result.get("hasPredictions"),
            ) # log success
            return result # completed prediction JSON
        time.sleep(poll_interval_seconds) # wait one interval

    raise TimeoutError(
        f"Timed out after {timeout_seconds}s waiting for predictor callback "
        f"(task_id={task_id}). Check CALLBACK_BASE_URL is the EC2 Tailscale address "
        f"reachable from the predictor desktop."
    ) # surface clear timeout


########## RUN PREDICTIONS ##########

def run_predictions(ohlcv_data, num_predictions=5): # function to send timeseries then wait for completed prediction JSON

    callback_store.clear_pending_prediction_result() # ignore stale callbacks
    num_predictions = max(1, min(int(num_predictions), 5)) # enforce predictor cap
    ack = send_timeseries_to_predictor(ohlcv_data, num_predictions=num_predictions) # enqueue
    task_id = ack.get("task_id") # extract task id if present
    logger.info("Predictor accepted task_id=%s", task_id) # log enqueue
    return wait_for_predictions(task_id=task_id) # block until callback
