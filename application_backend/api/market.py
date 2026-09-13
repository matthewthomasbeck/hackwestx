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
        payload = frontend_delivery.build_real_plus_predictions_payload(
            bundle["real"],
            bundle["predictions"],
            bundle.get("forecast_days") or 3,
        ) # compose ready payload
        frontend_delivery.send_to_frontend(payload) # warm cache
        return jsonify(payload), 200 # serve Tiger snapshot
    except Exception as e: # Tiger miss / not configured
        logger.info("No cached payload and Tiger fallback failed: %s", e) # log miss
        return jsonify({
            "asset": "SOL",
            "status": "empty",
            "real": None,
            "predictions": None,
            "message": "No market snapshot cached yet; trigger /api/v1/market/refresh",
        }), 200 # empty snapshot until refresh


########## REFRESH MARKET ##########

@api_bp.route("/market/refresh", methods=["POST"]) # register POST /api/v1/market/refresh
@require_auth # require Flutter user Auth0 access token
def refresh_market(): # function to trigger yfinance → Tiger → predictor → frontend pipeline

    body = request.get_json(silent=True) or {} # optional JSON body
    force = bool(body.get("force", False)) # force update flag
    forecast_days = body.get("forecast_days") # optional horizon override

    try:
        summary = run_solana_update_pipeline(
            forecast_days=forecast_days,
            force=force,
        ) # run orchestration
        return jsonify({"status": "ok", "summary": summary}), 200 # success summary
    except TimeoutError as e: # predictor callback never arrived
        logger.error("Market refresh timed out waiting for predictor: %s", e) # log
        return jsonify({"status": "error", "message": str(e)}), 504 # gateway timeout
    except NotImplementedError as e: # unfinished step
        logger.warning("Pipeline hit unimplemented step: %s", e) # soft fail
        return jsonify({
            "status": "skeleton",
            "message": str(e),
        }), 501 # not implemented
    except Exception as e: # unexpected failure
        logger.error("Market refresh failed: %s", e, exc_info=True) # log stack
        return jsonify({"status": "error", "message": str(e)}), 500 # server error


########## SOLANA PREDICTION CALLBACK ##########

@api_bp.route("/callback/solana", methods=["POST"]) # register POST /api/v1/callback/solana
def solana_prediction_callback(): # function to receive completed predictions from predictor_backend

    payload = request.get_json(silent=True) # parse callback body
    if not payload: # require JSON
        return jsonify({"status": "error", "message": "No JSON body"}), 400 # bad request

    logger.info("Received solana predictions callback (keys=%s)", list(payload.keys())) # log keys
    callback_store.set_pending_prediction_result(payload) # unblock wait_for_predictions

    # Best-effort persist even if the waiter path also upserts (idempotent ON CONFLICT)
    try:
        num_predictions = int(payload.get("numPredictions") or 3) # horizon from callback
        rows = prediction_client.callback_to_prediction_rows(
            payload,
            num_predictions=num_predictions,
        ) # Tiger rows
        if rows: # have forecasts
            written = tiger_db.upsert_predictions(rows) # persist
            logger.info("Callback persisted %s prediction rows to Tiger", written) # log
    except Exception as e: # persist failure path
        logger.error("Failed to persist callback predictions: %s", e, exc_info=True) # log
        return jsonify({
            "status": "received_but_persist_failed",
            "error": str(e),
        }), 200 # still ack receipt so waiter unblocks

    return jsonify({"status": "received", "asset": "SOL"}), 200 # callback ack
