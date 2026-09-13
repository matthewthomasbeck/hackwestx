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
from typing import Any, Dict, Optional # import typing helpers

##### import third-party libraries #####

import requests # import requests for HTTP calls to predictor_backend
from dotenv import load_dotenv # import dotenv to load predictor env vars

##### import local modules #####

from helpers.auth0 import get_m2m_token # import Auth0 M2M token helper for predictor auth

##### load environment #####

load_dotenv() # load predictor Tailscale URL and callback settings





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





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





##################################################
############### PREDICTION CLIENT ################
##################################################


########## BUILD PREDICTION PAYLOAD ##########

def build_prediction_payload(ohlcv_data, num_predictions, callback_url=None): # function to shape Tiger OHLCV into predictor JSON

    payload: Dict[str, Any] = {
        "asset": "SOL",
        "numPredictions": num_predictions,
        "timeSeries": ohlcv_data,
    } # base predictor payload
    if callback_url: # optional async callback
        payload["callback_url"] = callback_url # attach callback URL
    return payload # shaped JSON for predictor


########## SEND TIMESERIES TO PREDICTOR ##########

def send_timeseries_to_predictor( # function to POST SOL timeseries to predictor_backend with Auth0 M2M Bearer token
        ohlcv_data,
        num_predictions=7,
        callback_url=None
):

    if callback_url is None: # default callback from env
        callback_base = os.getenv("CALLBACK_BASE_URL", "http://localhost:8080") # app base
        callback_url = f"{callback_base.rstrip('/')}/callback/solana" # root callback path

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
        "Sending SOL timeseries to predictor at %s (num_predictions=%s callback=%s)",
        endpoint,
        num_predictions,
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

def wait_for_predictions( # function to block until predictor callback/status provides completed predictions
        task_id=None,
        timeout_seconds=600,
        poll_interval_seconds=2.0
):

    logger.info(
        "Waiting for predictor completion (task_id=%s timeout=%ss)",
        task_id,
        timeout_seconds,
    ) # log wait start

    # TODO options:
    #   1) threading.Event + global/callback store filled by /callback/solana
    #   2) poll GET {PREDICTOR_BASE_URL}/api/v1/status/{task_id}
    deadline = time.time() + timeout_seconds # absolute timeout
    while time.time() < deadline: # placeholder poll loop
        time.sleep(poll_interval_seconds) # wait one interval
        break # remove when real wait is implemented

    raise NotImplementedError(
        "Wire callback result store or status polling for predictor completion"
    ) # unfinished wait path


########## RUN PREDICTIONS ##########

def run_predictions(ohlcv_data, num_predictions=7): # function to send timeseries then wait for completed prediction JSON

    ack = send_timeseries_to_predictor(ohlcv_data, num_predictions=num_predictions) # enqueue
    task_id = ack.get("task_id") # extract task id if present
    return wait_for_predictions(task_id=task_id) # block until complete
