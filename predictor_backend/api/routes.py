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

import logging # import logging for route diagnostics

##### import third-party libraries #####

from flask import Blueprint, current_app, jsonify, request # import Flask request/response helpers

##### import local modules #####

from api.auth import verify_api_key # import Bearer auth decorator for predict routes
from helpers.solana import is_solana_request, normalize_incoming_payload # import optional SOL payload adapters
from utils.json_formatter import validate_json_structure # import timeSeries JSON schema checks





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE BLUEPRINT / LOGGER ##########

api_bp = Blueprint("api", __name__) # create blueprint for /api/v1 prediction routes
logger = logging.getLogger(__name__) # create module logger





##################################################
############### PREDICTION ROUTES ################
##################################################


########## PREDICT ##########

@api_bp.route("/predict", methods=["POST"]) # register POST /api/v1/predict
@verify_api_key # require Authorization Bearer (Auth0 M2M or interim key)
def predict(): # function to validate JSON, enqueue prediction task, return 202 + task_id

    try:
        metric_name = request.headers.get("X-Metric-Name", "unknown") # optional metric label
        logger.info(f"Received prediction request for metric: {metric_name}")

        json_data = request.get_json() # parse body

        if json_data is None:
            return jsonify({
                "error": "Bad Request",
                "message": "Request body must be valid JSON"
            }), 400

        if is_solana_request(json_data, request.headers) is True: # optional SOL adaptation (stub may return None)
            normalized = normalize_incoming_payload(json_data)
            if normalized is not None:
                json_data = normalized

        try:
            validate_json_structure(json_data) # schema check
        except ValueError as e:
            return jsonify({
                "error": "Bad Request",
                "message": str(e)
            }), 400

        callback_url = (
            request.args.get("callback_url") or
            json_data.get("callback_url") or
            request.headers.get("X-Callback-URL")
        ) # callback from query, body, or header

        queue_manager = current_app.queue_manager # app-attached queue

        try:
            task_id = queue_manager.enqueue(json_data, callback_url) # enqueue work
            logger.info(f"Task {task_id} queued for metric: {metric_name}")

            return jsonify({
                "status": "accepted",
                "task_id": task_id,
                "message": "Task queued for processing"
            }), 202

        except RuntimeError as e:
            logger.error(f"Failed to enqueue task: {e}")
            return jsonify({
                "error": "Service Unavailable",
                "message": "Queue is full, please try again later"
            }), 503

    except Exception as e:
        logger.error(f"Error in predict endpoint: {e}", exc_info=True)
        return jsonify({
            "error": "Internal Server Error",
            "message": "An error occurred processing your request"
        }), 500


########## GET TASK STATUS ##########

@api_bp.route("/status/<task_id>", methods=["GET"]) # register GET /api/v1/status/<task_id>
@verify_api_key # require Authorization Bearer (Auth0 M2M or interim key)
def get_task_status(task_id): # function to return simplified status for a queued/active task_id

    return jsonify({
        "task_id": task_id,
        "status": "processing", # simplified placeholder
        "message": "Task status check not fully implemented"
    }), 200
