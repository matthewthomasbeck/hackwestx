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

import logging # import logging for route diagnostics
import threading # import threading so refresh can return while predictions run

##### import third-party libraries #####

from flask import Blueprint, g, jsonify, request # import Flask request/response helpers

##### import local modules #####

from helpers.auth0 import require_auth # import Auth0 bearer-token decorator for Flutter users
from helpers import callback_store # import predictor callback result store
from helpers import frontend_delivery # import frontend payload cache helpers
from helpers import prediction_client # import callback→Tiger row helpers
from helpers import tiger_db # import Tiger read helpers for market fallback
from helpers.pipeline import run_solana_update_pipeline # import Solana update orchestration





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE BLUEPRINT / LOGGER ##########

api_bp = Blueprint("api", __name__) # create blueprint for Auth0-protected market API
logger = logging.getLogger(__name__) # create module logger
_pipeline_lock = threading.Lock() # serialize overlapping refresh / startup pipelines
_pipeline_running = False # True while a background Solana update is in flight





##################################################
############### PAYLOAD HELPERS ##################
##################################################


########## EMPTY MARKET PAYLOAD ##########

def _empty_market_payload(message=None): # function to build empty /market JSON for Flutter

    return {
        "asset": "SOL",
        "status": "empty",
        "real": None,
        "predictions": None,
        "message": message or "No market snapshot cached yet; trigger /api/v1/market/refresh",
    } # empty snapshot until refresh


########## PAYLOAD FROM TIGER BUNDLE ##########

def _payload_from_tiger_bundle(bundle, forecast_days=None): # function to map Tiger rows → ready/pending/empty

    real = bundle.get("real") or {"asset": "SOL", "series": []} # OHLCV blob
    predictions = bundle.get("predictions") or {"asset": "SOL", "series": []} # forecast blob
    real_series = real.get("series") or [] # candle list
    pred_series = predictions.get("series") or [] # forecast list
    horizon = forecast_days or bundle.get("forecast_days") or 3 # default 3-day view

    if not real_series: # nothing in Tiger yet
        return _empty_market_payload("Tiger sol_ohlcv is empty; trigger /api/v1/market/refresh") # empty

    if not pred_series: # real prices only — predictions still missing
        return frontend_delivery.build_real_only_payload(real) # predictions_pending

    return frontend_delivery.build_real_plus_predictions_payload(
        real,
        predictions,
        horizon,
    ) # ready for charts


########## RUN PIPELINE IN BACKGROUND ##########

def _run_pipeline_background(forecast_days, force): # function to run Solana update off the request thread

    global _pipeline_running # mutate module flag
    try:
        summary = run_solana_update_pipeline(
            forecast_days=forecast_days,
            force=force,
        ) # full yfinance → Tiger → predictor cycle
        logger.info("Background market pipeline finished: %s", summary) # log summary
    except Exception as e: # keep serving API even if refresh fails
        logger.error("Background market pipeline failed: %s", e, exc_info=True) # log stack
    finally:
        _pipeline_running = False # clear busy flag
        _pipeline_lock.release() # allow next refresh





##################################################
############### AUTH / MARKET ROUTES #############
##################################################


########## ME ##########

@api_bp.route("/me", methods=["GET"]) # register GET /api/v1/me
@require_auth # require Flutter user Auth0 access token
def me(): # function to return Auth0 sub/claims for the logged-in user

    return jsonify({
        "sub": getattr(g, "user_sub", None),
        "claims": getattr(g, "user_claims", {}),
    }), 200 # Auth0 identity for Flutter


########## GET MARKET ##########

@api_bp.route("/market", methods=["GET"]) # register GET /api/v1/market
@require_auth # require Flutter user Auth0 access token
def get_market(): # function to serve cached SOL real (+ predictions) JSON to Flutter

    cached = frontend_delivery.get_cached_frontend_payload() # in-memory snapshot
    if cached is not None: # cache hit
        return jsonify(cached), 200 # serve cached market JSON

    try:
        bundle = tiger_db.read_market_bundle() # fall back to Tiger
        payload = _payload_from_tiger_bundle(bundle) # empty | pending | ready
        if payload.get("status") != "empty": # warm cache when Tiger has data
            frontend_delivery.send_to_frontend(payload) # so later GETs skip DB
        return jsonify(payload), 200 # serve Tiger-derived snapshot
    except Exception as e: # Tiger miss / not configured
        logger.info("No cached payload and Tiger fallback failed: %s", e) # log miss
        return jsonify(_empty_market_payload()), 200 # empty snapshot until refresh


########## REFRESH MARKET ##########

@api_bp.route("/market/refresh", methods=["POST"]) # register POST /api/v1/market/refresh
@require_auth # require Flutter user Auth0 access token
def refresh_market(): # function to start yfinance → Tiger → predictor pipeline in a background thread

    global _pipeline_running # mutate busy flag
    body = request.get_json(silent=True) or {} # optional JSON body
    force = bool(body.get("force", False)) # force update flag
    forecast_days = body.get("forecast_days") # optional horizon override

    if not _pipeline_lock.acquire(blocking=False): # another refresh already running
        return jsonify({
            "status": "busy",
            "message": "Market pipeline already running; poll GET /api/v1/market",
            "pipeline_running": True,
        }), 409 # conflict — Flutter should keep polling

    _pipeline_running = True # mark busy before returning
    thread = threading.Thread(
        target=_run_pipeline_background,
        args=(forecast_days, force),
        daemon=True,
        name="solana-market-pipeline",
    ) # predictions can take minutes — do not block HTTP
    thread.start() # kick off update

    return jsonify({
        "status": "started",
        "message": "Market pipeline started; poll GET /api/v1/market until status is ready",
        "pipeline_running": True,
        "force": force,
        "forecast_days": forecast_days,
    }), 202 # accepted — Flutter polls for real then predictions


########## SOLANA PREDICTION CALLBACK ##########

@api_bp.route("/callback/solana", methods=["POST"]) # register POST /api/v1/callback/solana
def solana_prediction_callback(): # function to receive completed predictions from predictor_backend

    payload = request.get_json(silent=True) # parse callback body
    if not payload: # require JSON
        return jsonify({"status": "error", "message": "No JSON body"}), 400 # bad request

    logger.info("Received solana predictions callback (keys=%s)", list(payload.keys())) # log keys
    callback_store.set_pending_prediction_result(payload) # unblock wait_for_predictions

    # Best-effort persist + push ready JSON so Flutter polls see predictions immediately
    try:
        num_predictions = int(payload.get("numPredictions") or 3) # horizon from callback
        rows = prediction_client.callback_to_prediction_rows(
            payload,
            num_predictions=num_predictions,
        ) # Tiger rows
        if rows: # have forecasts
            written = tiger_db.upsert_predictions(rows) # persist
            logger.info("Callback persisted %s prediction rows to Tiger", written) # log
            predictions = prediction_client.callback_to_frontend_predictions(
                payload,
                num_predictions=num_predictions,
            ) # frontend-shaped series
            try:
                ohlcv_data = tiger_db.read_ohlcv() # latest real prices for chart
            except Exception as read_err: # Tiger read failure — keep waiter path working
                logger.warning("Callback could not read OHLCV for frontend cache: %s", read_err) # soft
                ohlcv_data = None # skip ready cache
            if ohlcv_data and (ohlcv_data.get("series") or []): # can compose ready payload
                frontend_delivery.send_to_frontend(
                    frontend_delivery.build_real_plus_predictions_payload(
                        ohlcv_data,
                        predictions,
                        num_predictions,
                    )
                ) # Flutter poll flips from pending → ready
    except Exception as e: # persist failure path
        logger.error("Failed to persist callback predictions: %s", e, exc_info=True) # log
        return jsonify({
            "status": "received_but_persist_failed",
            "error": str(e),
        }), 200 # still ack receipt so waiter unblocks

    return jsonify({"status": "received", "asset": "SOL"}), 200 # callback ack
