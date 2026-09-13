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

from flask import Blueprint, jsonify # import Flask blueprint and JSON response helpers





##################################################
############### HEALTH BLUEPRINT #################
##################################################


########## CREATE BLUEPRINT ##########

health_bp = Blueprint("health", __name__) # create blueprint for health/root routes





##################################################
############### HEALTH ROUTES ####################
##################################################


########## HEALTH ##########

@health_bp.route("/health", methods=["GET"]) # register GET /health
def health(): # function to return service health JSON for uptime checks

    return jsonify({
        "status": "healthy",
        "service": "application_backend",
    }), 200 # liveness probe response


########## ROOT ##########

@health_bp.route("/", methods=["GET"]) # register GET /
def root(): # function to list available application_backend endpoints

    return jsonify({
        "service": "application_backend",
        "endpoints": {
            "health": "/health",
            "market": "/api/v1/market",
            "refresh": "/api/v1/market/refresh",
            "callback": "/callback/solana",
            "me": "/api/v1/me",
        },
    }), 200 # service name + endpoint map
