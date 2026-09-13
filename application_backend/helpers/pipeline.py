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

    ##### 1) latest Tiger timestamp #####

    # last_time = tiger_db.get_latest_ohlcv_time()
    last_time = None # skeleton placeholder until tiger_db is wired
    summary["last_tiger_time"] = last_time.isoformat() if last_time else None # record last time

    if not force and not needs_update(last_time): # already current
        logger.info("Tiger OHLCV already current — skipping fetch/predict") # skip work
        # Still refresh frontend cache from Tiger when implemented
        # bundle = tiger_db.read_market_bundle(forecast_days=forecast_days)
        # frontend_delivery.send_to_frontend(
        #     frontend_delivery.build_real_plus_predictions_payload(
        #         bundle["real"], bundle["predictions"], forecast_days
        #     )
        # )
        summary["reason"] = "already_up_to_date" # no fetch needed
        return summary # early exit

    ##### 2) fetch yfinance and upsert real prices #####

    # new_rows = yfinance_solana.fetch_solana_since(last_time)
    # tiger_db.upsert_ohlcv(new_rows)
    # ohlcv_data = tiger_db.read_ohlcv()
    ohlcv_data: Dict[str, Any] = {"asset": "SOL", "series": []} # skeleton empty series
    summary["updated"] = True # mark update attempted

    ##### 3) serve real data to frontend while predictions run #####

    real_payload = frontend_delivery.build_real_only_payload(ohlcv_data) # predictions_pending
    frontend_delivery.send_to_frontend(real_payload) # cache/webhook

    ##### 4) call predictor, wait, persist predictions #####

    # prediction_json = prediction_client.run_predictions(ohlcv_data, num_predictions=forecast_days)
    # tiger_db.upsert_predictions(prediction_json["rows"])
    # predictions = tiger_db.read_predictions()
    predictions: Dict[str, Any] = {"series": []} # skeleton empty forecasts
    summary["predictions_run"] = True # mark predict step reached

    ##### 5–6) serve real + predictions #####

    final_payload = frontend_delivery.build_real_plus_predictions_payload(
        ohlcv_data,
        predictions,
        forecast_days,
    ) # ready payload
    frontend_delivery.send_to_frontend(final_payload) # cache/webhook final

    logger.info("Solana update pipeline skeleton finished") # log done
    summary["reason"] = "skeleton_completed" # stash-level completion
    return summary # return for refresh API / logs
