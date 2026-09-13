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

import atexit # import atexit to register process-exit shutdown hooks
import logging # import logging for startup/shutdown messages
import signal # import signal for SIGINT/SIGTERM graceful shutdown
import sys # import sys for optional hard-exit on startup failure

##### import third-party libraries #####

from dotenv import load_dotenv # import dotenv to load .env into process env
from flask import Flask # import Flask application factory type
import torch # import torch for CUDA cache cleanup on shutdown

##### import local modules #####

from api.health import health_bp # import health/status blueprint
from api.routes import api_bp # import predict/status API blueprint
from config import config # import declarative service configuration
from models.model_loader import ModelManager # import LSTM load/device manager
from task_queue import QueueManager # import prediction task queue
from utils.logging_setup import setup_logging # import logging configuration helper
from workers.worker_manager import WorkerManager # import GPU/CPU worker pool manager

##### load environment #####

load_dotenv() # load predictor_backend/.env values





##################################################
############### MODULE STATE #####################
##################################################


########## LIFECYCLE REFS ##########

queue_manager = None # set by create_app(); used by shutdown_handler
model_manager = None # set by create_app(); used by shutdown_handler
worker_manager = None # set by create_app(); used by shutdown_handler
logger = logging.getLogger(__name__) # module logger for lifecycle messages





##################################################
############### FLASK APPLICATION ################
##################################################


########## CREATE APP ##########

def create_app(): # function to build Flask app, init queue/model/workers, register blueprints

    global queue_manager, model_manager, worker_manager # expose for shutdown_handler

    app = Flask(__name__) # create Flask application

    logger.info("Initializing components...")
    queue_manager = QueueManager() # prediction task queue
    model_manager = ModelManager() # LSTM load/device manager
    worker_manager = WorkerManager(queue_manager, model_manager) # GPU/CPU worker pool

    app.queue_manager = queue_manager # attach for routes/health
    app.model_manager = model_manager
    app.worker_manager = worker_manager

    app.register_blueprint(api_bp, url_prefix="/api/v1") # predict + task status
    app.register_blueprint(health_bp) # /health + /status
    health_bp.app = app # stash-compatible health app ref

    return app





##################################################
############### LIFECYCLE ########################
##################################################


########## SHUTDOWN HANDLER ##########

def shutdown_handler(signum=None, frame=None): # function to gracefully stop workers and clear CUDA on exit

    logger.info("Shutdown signal received, initiating graceful shutdown...")

    if worker_manager is not None:
        worker_manager.shutdown() # stop workers + queue

    if model_manager is not None and getattr(model_manager, "model", None) is not None:
        logger.info("Cleaning up model...")
        if torch.cuda.is_available():
            torch.cuda.empty_cache() # free GPU memory

    logger.info("Shutdown complete")
    sys.exit(0)


########## STARTUP ##########

def startup(app): # function to load LSTM weights and start GPU/CPU worker threads

    logger.info("Starting up prediction service...")

    try:
        app.model_manager.load_model() # load LSTM onto device
        logger.info("Model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model: {e}", exc_info=True)
        raise

    try:
        app.worker_manager.start() # spawn GPU/CPU threads
        logger.info("Workers started successfully")
    except Exception as e:
        logger.error(f"Failed to start workers: {e}", exc_info=True)
        raise

    logger.info("Prediction service started successfully")





##################################################
############### ENTRYPOINT #######################
##################################################


########## MAIN ##########

def main(): # function to setup logging, validate config, create app, startup, then serve Flask

    setup_logging() # configure logging handlers

    try:
        config.validate() # fail fast on bad config
    except ValueError as e:
        logger.error(f"Configuration error: {e}")
        sys.exit(1)

    app = create_app() # build Flask app + managers

    signal.signal(signal.SIGINT, shutdown_handler) # Ctrl-C
    signal.signal(signal.SIGTERM, shutdown_handler) # terminate
    atexit.register(shutdown_handler) # process exit

    try:
        startup(app) # load model + start workers
    except Exception as e:
        logger.error(f"Failed to start service: {e}")
        sys.exit(1)

    try:
        logger.info(f"Starting Flask server on {config.HOST}:{config.PORT}")
        app.run(
            host=config.HOST,
            port=config.PORT,
            debug=False,
            threaded=True
        )
    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received")
    finally:
        shutdown_handler()


##### run when executed directly #####

if __name__ == "__main__": # if this file is the program entrypoint...
    main() # start predictor_backend
