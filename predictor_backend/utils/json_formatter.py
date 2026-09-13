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

import json # import json for prepare_response_json stringification
import logging # import logging for structure diagnostics
from typing import Any, Dict, List # import typing helpers





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### JSON STRUCTURE HELPERS ###########
##################################################


########## VALIDATE JSON STRUCTURE ##########

def validate_json_structure(data: Dict[str, Any]) -> None: # function to require timeSeries/xAxis/yAxis and valid numPredictions

    required_fields = ["timeSeries", "xAxis", "yAxis"] # mandatory top-level keys
    for field in required_fields: # check each required field
        if field not in data: # missing key
            raise ValueError(f"Missing required field: {field}") # fail validation

    if not isinstance(data["timeSeries"], list): # timeSeries must be a list
        raise ValueError("timeSeries must be a list") # reject bad type

    if len(data["timeSeries"]) == 0: # need at least one series
        raise ValueError("timeSeries cannot be empty") # reject empty payload

    ##### validate numPredictions if present #####

    if "numPredictions" in data: # optional but constrained when set
        import config # local import to avoid circulars at module load
        max_preds = config.config.MAX_PREDICTIONS # hard cap from config
        num_preds = data["numPredictions"] # requested future steps
        if not isinstance(num_preds, int) or num_preds < 1 or num_preds > max_preds: # must be 1..MAX
            raise ValueError(
                f"numPredictions must be an integer between 1 and {max_preds}"
            ) # reject bad value


########## EXTRACT SERIES FROM JSON ##########

def extract_series_from_json(data: Dict[str, Any]) -> List[Dict[str, Any]]: # function to return the timeSeries list from inbound JSON

    return data.get("timeSeries", []) # return series list or empty


########## FORMAT PREDICTIONS FOR JSON ##########

def format_predictions_for_json(
    series_name: str,
    times: List[str],
    fitted_predictions: List[float],
    future_times: List[str],
    future_predictions: List[float],
) -> Dict[str, Any]: # function to build one {name, data:[{x,y}]} series from fitted + future points

    ##### combine historical fitted predictions #####

    historical_data = [
        {"x": time, "y": float(pred)}
        for time, pred in zip(times, fitted_predictions)
    ] # zip historical x with fitted y

    ##### add future predictions #####

    future_data = [
        {"x": time, "y": float(pred)}
        for time, pred in zip(future_times, future_predictions)
    ] # zip future x with future y

    return {
        "name": series_name,
        "data": historical_data + future_data
    } # timeSeries-shaped prediction series


########## INJECT PREDICTIONS INTO JSON ##########

def inject_predictions_into_json(
    original_json: Dict[str, Any],
    predictions: List[Dict[str, Any]],
    num_predictions: int,
) -> Dict[str, Any]: # function to copy payload, drop callback_url, set hasPredictions + predictions[]

    ##### create a copy to avoid modifying original #####

    result = original_json.copy() # shallow copy of inbound payload

    ##### remove internal fields that shouldn't be in the response #####

    result.pop('callback_url', None) # strip callback URL from client response

    ##### update metadata #####

    result["hasPredictions"] = "True" # mark predictions present
    result["numPredictions"] = num_predictions # echo steps predicted

    ##### add predictions array #####

    result["predictions"] = predictions # attach per-series prediction objects

    return result # enriched response dict


########## PREPARE RESPONSE JSON ##########

def prepare_response_json(
    original_json: Dict[str, Any],
    predictions: List[Dict[str, Any]],
    num_predictions: int,
) -> str: # function to serialize injected prediction JSON as an indented string

    result = inject_predictions_into_json(original_json, predictions, num_predictions) # inject then dump
    return json.dumps(result, indent=2) # indented JSON string
