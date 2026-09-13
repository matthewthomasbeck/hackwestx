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

        pass # skeleton: prefer helpers.auth0.validate_m2m_token when AUTH0_DOMAIN set; else shared-secret compare

    return decorated_function # return wrapped Flask view
