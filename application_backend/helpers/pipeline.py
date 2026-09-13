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

import logging # import logging for pipeline orchestration messages
import os # import os for FORECAST_DAYS and related settings
from datetime import date, datetime, timezone # import date helpers for update checks
from typing import Any, Dict, Optional # import typing helpers

##### import local modules #####

from helpers import frontend_delivery # import frontend JSON builders/delivery
from helpers import prediction_client # import predictor send/wait helpers
from helpers import tiger_db # import Tiger Cloud read/write helpers
from helpers import yfinance_solana # import yfinance SOL OHLCV fetch helpers





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### DATE HELPERS #####################
##################################################


########## AS DATE ##########

def _as_date(value): # function to normalize datetime/date/None into a calendar date

    if value is None: # empty input
        return None # no date
    if isinstance(value, datetime): # datetime → date
        return value.date() # calendar date
    return value # already a date


########## NEEDS UPDATE ##########

def needs_update(last_entry, today=None): # function to check if calendar today is later than last Tiger OHLCV date

    today = today or datetime.now(timezone.utc).date() # default to UTC today
    last_date = _as_date(last_entry) # normalize last entry
    if last_date is None: # empty table / no prior data
        return True # needs full update
    return today > last_date # True when calendar today is later





##################################################
############### SOLANA UPDATE PIPELINE ###########
##################################################


########## RUN SOLANA UPDATE PIPELINE ##########

def run_solana_update_pipeline(forecast_days=None, force=False): # function to orchestrate one SOL data + prediction update cycle

    ##### intended flow when implemented #####

    # 1) read latest Tiger sol_ohlcv timestamp
    # 2) if force or needs_update: fetch yfinance, upsert real prices
    # 3) send real-only JSON to frontend while predictions run
    # 4) send Tiger timeseries JSON to predictor_backend (Auth0 M2M), wait
    # 5) upsert predictions into Tiger sol_predictions
    # 6) send real + x-day predictions JSON to frontend

    forecast_days = forecast_days or int(os.getenv("FORECAST_DAYS", "7")) # horizon from arg/env
    summary: Dict[str, Any] = {
        "asset": "SOL",
        "forecast_days": forecast_days,
        "updated": False,
        "predictions_run": False,
    } # API/logging summary

    logger.info("Starting Solana update pipeline (forecast_days=%s force=%s)", forecast_days, force) # log start

    ##### 0) schema (idempotent) #####

    tiger_db.ensure_schema() # create hypertables / PK(time) if missing

    ##### 1) latest Tiger timestamp #####

    last_time = tiger_db.get_latest_ohlcv_time() # MAX(time) from sol_ohlcv
    summary["last_tiger_time"] = last_time.isoformat() if last_time else None # record last time

    if not force and not needs_update(last_time): # already current
        logger.info("Tiger OHLCV already current — skipping fetch/predict") # skip work
        bundle = tiger_db.read_market_bundle(forecast_days=forecast_days) # reload cache from Tiger
        frontend_delivery.send_to_frontend(
            frontend_delivery.build_real_plus_predictions_payload(
                bundle["real"], bundle["predictions"], forecast_days
            )
        ) # serve cached Tiger snapshot
        summary["reason"] = "already_up_to_date" # no fetch needed
        return summary # early exit

    ##### 2) fetch yfinance and upsert real prices #####

    new_rows = yfinance_solana.fetch_solana_since(None if force else last_time) # full or incremental
    written = tiger_db.upsert_ohlcv(new_rows) # persist candles
    summary["rows_fetched"] = len(new_rows) # yfinance count
    summary["rows_upserted"] = written # tiger write count
    ohlcv_data = tiger_db.read_ohlcv() # read-back for frontend / later predictor
    summary["updated"] = True # mark update attempted

    # Console-friendly sample so local/EC2 logs prove the path works
    series = ohlcv_data.get("series") or [] # full series
    sample = series[-3:] if series else [] # last few candles
    logger.info(
        "SOL OHLCV ready (bars=%s sample_tail=%s)",
        len(series),
        sample,
    ) # print usable proof to console/logs

    ##### 3) serve real data to frontend while predictions run #####

    real_payload = frontend_delivery.build_real_only_payload(ohlcv_data) # predictions_pending
    frontend_delivery.send_to_frontend(real_payload) # cache/webhook

    ##### 4) call predictor, wait, persist predictions #####

    num_predictions = max(1, min(int(forecast_days), 5)) # predictor hard cap is 5
    summary["num_predictions"] = num_predictions # record capped horizon
    callback_payload = prediction_client.run_predictions(
        ohlcv_data,
        num_predictions=num_predictions,
    ) # Auth0 M2M → predictor → /callback/solana
    prediction_rows = prediction_client.callback_to_prediction_rows(
        callback_payload,
        num_predictions=num_predictions,
    ) # future closes for Tiger
    written_preds = tiger_db.upsert_predictions(prediction_rows) # persist forecasts
    summary["prediction_rows_upserted"] = written_preds # tiger write count
    predictions = prediction_client.callback_to_frontend_predictions(
        callback_payload,
        num_predictions=num_predictions,
    ) # frontend-shaped forecasts
    summary["predictions_run"] = True # predict step completed
    summary["predictions_sample"] = predictions.get("series") # console-friendly proof

    logger.info(
        "SOL predictions ready (rows=%s sample=%s)",
        written_preds,
        predictions.get("series"),
    ) # print usable proof to console/logs

    ##### 5–6) serve real + predictions #####

    final_payload = frontend_delivery.build_real_plus_predictions_payload(
        ohlcv_data,
        predictions,
        num_predictions,
    ) # ready payload
    frontend_delivery.send_to_frontend(final_payload) # cache/webhook final

    logger.info("Solana update pipeline finished (yfinance + Tiger + predictor)") # log done
    summary["reason"] = "ohlcv_and_predictions_updated" # full path completed
    summary["forecast_days"] = num_predictions # echo effective horizon
    return summary # return for refresh API / logs
