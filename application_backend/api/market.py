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
from typing import Any, Dict # import typing helpers for callback payload store

##### import third-party libraries #####

from flask import Blueprint, g, jsonify, request # import Flask request/response helpers

##### import local modules #####

from helpers.auth0 import require_auth # import Auth0 bearer-token decorator for Flutter users
from helpers import frontend_delivery # import frontend payload cache helpers
from helpers.pipeline import run_solana_update_pipeline # import Solana update orchestration





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE BLUEPRINT / LOGGER / STORE ##########

api_bp = Blueprint("api", __name__) # create blueprint for Auth0-protected market API
logger = logging.getLogger(__name__) # create module logger

_pending_prediction_result: Dict[str, Any] | None = None # store last predictor callback payload





##################################################
############### CALLBACK RESULT STORE ############
##################################################


########## GET PENDING PREDICTION RESULT ##########

def get_pending_prediction_result(): # function to return last predictor callback payload if present

    return _pending_prediction_result # last callback JSON or None


########## SET PENDING PREDICTION RESULT ##########

def set_pending_prediction_result(payload): # function to save predictor callback JSON for waiters/pipeline

    global _pending_prediction_result # mutate module store
    _pending_prediction_result = payload # save callback JSON





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

    # TODO: fall back to tiger_db.read_market_bundle()
    logger.info("No cached payload — Tiger fallback not implemented yet") # log miss
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
    except NotImplementedError as e: # unfinished Tiger/yfinance/predictor step
        logger.warning("Pipeline skeleton hit unimplemented step: %s", e) # soft fail
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
    set_pending_prediction_result(payload) # store for waiters

    # TODO:
    #   1) normalize prediction rows
    #   2) tiger_db.upsert_predictions(...)
    #   3) build real+predictions payload and frontend_delivery.send_to_frontend(...)
    try:
        # tiger_db.upsert_predictions(...)  # noqa: skeleton
        pass # persist not wired yet
    except Exception as e: # persist failure path
        logger.error("Failed to persist callback predictions: %s", e, exc_info=True) # log
        return jsonify({
            "status": "received_but_persist_failed",
            "error": str(e),
        }), 200 # still ack receipt

    return jsonify({"status": "received", "asset": "SOL"}), 200 # callback ack
