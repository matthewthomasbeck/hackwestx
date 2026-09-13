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

import logging # import logging for auth failure diagnostics
import os # import os to detect AUTH0_DOMAIN for M2M path
from functools import wraps # import wraps to preserve Flask view metadata

##### import third-party libraries #####

from flask import jsonify, request # import Flask helpers used by verify_api_key

##### import local modules #####

import config # import service config for interim PREDICTION_SERVICE_KEY





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger aligned with service name





##################################################
############### API KEY / M2M AUTH ###############
##################################################


########## VERIFY API KEY ##########

def verify_api_key(f): # decorator to verify Authorization Bearer (Auth0 M2M or interim PREDICTION_SERVICE_KEY)

    @wraps(f) # preserve original view function name/docs
    def decorated_function(*args, **kwargs): # wrapped view that enforces Bearer auth

        auth_header = request.headers.get("Authorization", "") # read Authorization header

        if not auth_header.startswith("Bearer "): # require Bearer scheme
            logger.warning("Missing or invalid Authorization header")
            return jsonify({
                "error": "Unauthorized",
                "message": "Missing or invalid Authorization header"
            }), 401

        token = auth_header.replace("Bearer ", "").strip() # extract token string

        if os.getenv("AUTH0_DOMAIN"): # prefer Auth0 M2M when domain configured
            try:
                from helpers.auth0 import validate_m2m_token # lazy import (may still be stub)

                claims = validate_m2m_token(token) # verify JWT; stub returns None via pass
                if claims is not None: # real validator returned claims
                    request.m2m_claims = claims # type: ignore[attr-defined]
                    return f(*args, **kwargs) # proceed with authenticated view
            except Exception as e:
                logger.warning(f"Auth0 M2M validation failed: {e}")
                return jsonify({
                    "error": "Unauthorized",
                    "message": "Invalid M2M access token"
                }), 401

        if token != config.config.PREDICTION_SERVICE_KEY: # interim shared-secret check
            logger.warning(f"Invalid API key attempted: {token[:10]}...")
            return jsonify({
                "error": "Unauthorized",
                "message": "Invalid API key"
            }), 401

        return f(*args, **kwargs) # token valid — proceed

    return decorated_function # return wrapped Flask view
