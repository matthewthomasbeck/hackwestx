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

import logging # import logging for frontend delivery messages
import os # import os for optional FRONTEND_WEBHOOK_URL
from datetime import datetime, timezone # import datetime for payload updated_at stamps
from typing import Any, Dict, Optional # import typing helpers

##### import third-party libraries #####

import requests # import requests for optional webhook POST
from dotenv import load_dotenv # import dotenv to load frontend delivery env vars

##### load environment #####

load_dotenv() # load optional webhook configuration





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER / CACHE ##########

logger = logging.getLogger(__name__) # create module logger

_latest_payload: Optional[Dict[str, Any]] = None # in-memory market JSON served to Flutter via /market





##################################################
############### FRONTEND PAYLOAD CACHE ###########
##################################################


########## GET CACHED FRONTEND PAYLOAD ##########

def get_cached_frontend_payload(): # function to return last market JSON prepared for Flutter, if any

    return _latest_payload # return last cached market JSON or None


########## SET CACHED FRONTEND PAYLOAD ##########

def set_cached_frontend_payload(payload): # function to replace in-memory market JSON snapshot for API clients

    global _latest_payload # mutate module cache
    _latest_payload = payload # replace snapshot





##################################################
############### PAYLOAD BUILDERS #################
##################################################


########## BUILD REAL ONLY PAYLOAD ##########

def build_real_only_payload(ohlcv_data): # function to build frontend JSON while predictions are still running

    return {
        "asset": "SOL",
        "status": "predictions_pending",
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "real": ohlcv_data,
        "predictions": None,
    } # real prices only; predictions still running


########## BUILD REAL PLUS PREDICTIONS PAYLOAD ##########

def build_real_plus_predictions_payload( # function to build frontend JSON once real prices + forecasts are ready
        ohlcv_data,
        predictions,
        forecast_days
):

    return {
        "asset": "SOL",
        "status": "ready",
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "forecast_days": forecast_days,
        "real": ohlcv_data,
        "predictions": predictions,
    } # real prices + forecasts ready





##################################################
############### FRONTEND DELIVERY ################
##################################################


########## SEND TO FRONTEND ##########

def send_to_frontend(payload): # function to cache market JSON for /market and optionally POST a webhook

    set_cached_frontend_payload(payload) # always cache for GET /market
    logger.info(
        "Frontend payload cached (status=%s keys=%s)",
        payload.get("status"),
        list(payload.keys()),
    ) # log cache update

    webhook = os.getenv("FRONTEND_WEBHOOK_URL") # optional push URL
    if not webhook: # no webhook configured
        return # cache-only delivery

    logger.info("POSTing market payload to FRONTEND_WEBHOOK_URL") # log push attempt
    response = requests.post(webhook, json=payload, timeout=15) # POST market JSON
    if response.status_code >= 400: # webhook rejected payload
        logger.error(
            "Frontend webhook failed (%s): %s",
            response.status_code,
            response.text,
        ) # log failure body
        response.raise_for_status() # surface HTTP error
