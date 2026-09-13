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

import logging # import logging for status endpoint errors

##### import third-party libraries #####

from flask import Blueprint, current_app, jsonify # import Flask blueprint and JSON helpers
import torch # import torch for CUDA availability in /status





##################################################
############### HEALTH BLUEPRINT #################
##################################################


########## CREATE BLUEPRINT / LOGGER ##########

health_bp = Blueprint("health", __name__) # create blueprint for health/status routes
logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### HEALTH ROUTES ####################
##################################################


########## HEALTH ##########

@health_bp.route("/health", methods=["GET"]) # register GET /health
def health(): # function to return basic service health JSON for uptime checks

    return jsonify({
        "status": "healthy",
        "service": "prediction_service"
    }), 200 # basic liveness


########## STATUS ##########

@health_bp.route("/status", methods=["GET"]) # register GET /status
def status(): # function to return GPU, model, queue, and worker status snapshot

    try:
        app = current_app # Flask app with attached managers

        status_data = {
            "service": "prediction_service",
            "status": "running"
        } # base payload

        status_data["gpu"] = {
            "available": torch.cuda.is_available(),
            "device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0
        } # GPU availability

        if torch.cuda.is_available():
            status_data["gpu"]["device_name"] = torch.cuda.get_device_name(0)
            status_data["gpu"]["memory_total_gb"] = round(
                torch.cuda.get_device_properties(0).total_memory / 1e9, 2
            )

        if hasattr(app, "model_manager") and app.model_manager:
            model_manager = app.model_manager
            status_data["model"] = {
                "loaded": model_manager.is_loaded(),
                "device": str(model_manager.get_device())
            }
        else:
            status_data["model"] = {
                "loaded": False,
                "device": "unknown"
            }

        if hasattr(app, "queue_manager") and app.queue_manager:
            status_data["queue"] = app.queue_manager.get_stats()
        else:
            status_data["queue"] = {"error": "queue_manager not available"}

        if hasattr(app, "worker_manager") and app.worker_manager:
            status_data["workers"] = app.worker_manager.get_worker_stats()
        else:
            status_data["workers"] = {"error": "worker_manager not available"}

        return jsonify(status_data), 200

    except Exception as e:
        logger.error(f"Error in status endpoint: {e}", exc_info=True)
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500
