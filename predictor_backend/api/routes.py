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
logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### PREDICTION ROUTES ################
##################################################


########## PREDICT ##########

@api_bp.route("/predict", methods=["POST"]) # register POST /api/v1/predict
@verify_api_key # require Authorization Bearer (Auth0 M2M or interim key)
def predict(): # function to validate JSON, enqueue prediction task, return 202 + task_id

    pass # skeleton: optional SOL normalize → validate_json_structure → queue_manager.enqueue → 202


########## GET TASK STATUS ##########

@api_bp.route("/status/<task_id>", methods=["GET"]) # register GET /api/v1/status/<task_id>
@verify_api_key # require Authorization Bearer (Auth0 M2M or interim key)
def get_task_status(task_id): # function to return simplified status for a queued/active task_id

    pass # skeleton: return task_id + processing placeholder (full DB/cache status optional)
