############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for pipeline messages
import os # import os for environment variable access
import sys # import sys for optional hard-exit on startup failure

##### import third-party libraries #####

from dotenv import load_dotenv # import dotenv to load .env into process env
from flask import Flask # import Flask application factory type
from flask_cors import CORS # import CORS helper for Flutter clients

##### import local modules #####

from api.health import health_bp # import health/root blueprint
from api.market import api_bp, solana_prediction_callback # import market routes + callback view

##### load environment #####

from pathlib import Path # resolve .env next to this file (cwd-independent)

load_dotenv(Path(__file__).resolve().parent / ".env") # load application_backend/.env





##################################################
############### LOGGING SETUP ####################
##################################################


########## MODULE PATH FORMATTER ##########

class ModulePathFormatter(logging.Formatter): # class to render logger name as helpers/file.py

    def format(self, record: logging.LogRecord) -> str: # function to inject module_path then format

        name = record.name # dotted logger name from getLogger(__name__)
        if name in ("__main__", "root"): # entrypoint / root fallback
            record.module_path = "main.py" if name == "__main__" else "root"
        else:
            record.module_path = name.replace(".", "/") + ".py" # helpers/auth0.py style
        return super().format(record) # apply format string


########## SETUP LOGGING ##########

def setup_logging(): # function to configure root console/file logging from env

    log_level_str = os.getenv("LOG_LEVEL", "INFO").upper() # read level name from env
    level = getattr(logging, log_level_str, logging.INFO) # resolve to logging constant

    root = logging.getLogger() # configure root logger
    root.setLevel(level) # apply level

    formatter = ModulePathFormatter(
        "%(asctime)s - %(levelname)s (%(module_path)s): %(message)s"
    ) # timestamp - LEVEL (path/file.py): message

    if not any(
        isinstance(h, logging.StreamHandler) and not isinstance(h, logging.FileHandler)
        for h in root.handlers
    ): # avoid duplicate console
        ch = logging.StreamHandler() # stdout/stderr stream
        ch.setLevel(level) # match root level
        ch.setFormatter(formatter) # apply format
        root.addHandler(ch) # attach console handler
    else:
        for handler in root.handlers:
            if isinstance(handler, logging.StreamHandler) and not isinstance(handler, logging.FileHandler):
                handler.setFormatter(formatter)
                handler.setLevel(level)

    log_file = os.getenv("LOG_FILE") # optional file path
    if log_file: # file logging enabled
        log_dir = os.path.dirname(log_file) # parent directory
        if log_dir: # ensure directory exists
            os.makedirs(log_dir, exist_ok=True) # mkdir -p
        abs_path = os.path.abspath(log_file)
        existing = next(
            (
                h for h in root.handlers
                if isinstance(h, logging.FileHandler)
                and getattr(h, "baseFilename", None) == abs_path
            ),
            None,
        )
        if existing is None:
            fh = logging.FileHandler(log_file) # append to log file
            fh.setLevel(level) # match root level
            fh.setFormatter(formatter) # apply format
            root.addHandler(fh) # attach file handler
        else:
            existing.setFormatter(formatter)
            existing.setLevel(level)





##################################################
############### FLASK APPLICATION ################
##################################################


########## CREATE APP ##########

def create_app(): # function to build Flask app, register blueprints, and mount callback

    app = Flask(__name__) # create Flask application
    CORS(app, resources={r"/*": {"origins": os.getenv("CORS_ORIGINS", "*")}}) # allow Flutter origins

    app.register_blueprint(health_bp) # /health and /
    app.register_blueprint(api_bp, url_prefix="/api/v1") # market + me + refresh + callback

    ##### predictor callback (also available as /api/v1/callback/solana via blueprint) #####

    app.add_url_rule(
        "/callback/solana",
        endpoint="solana_prediction_callback_root",
        view_func=solana_prediction_callback,
        methods=["POST"],
    ) # mount root-level callback alias for predictor

    return app # configured Flask app





##################################################
############### ENTRYPOINT #######################
##################################################


########## MAIN ##########

def main(): # function to start logging, optional startup pipeline, then serve Flask API

    setup_logging() # configure console/file logging
    logger = logging.getLogger(__name__) # entrypoint logger

    host = os.getenv("HOST", "0.0.0.0") # bind host
    port = int(os.getenv("PORT", "8080")) # bind port

    app = create_app() # build Flask app + blueprints
    logger.info("Starting application_backend on %s:%s", host, port) # log listen addr

    ##### optional one-shot pipeline before serving #####

    if os.getenv("RUN_PIPELINE_ON_START", "false").lower() == "true": # opt-in startup refresh
        try:
            from helpers.pipeline import run_solana_update_pipeline # lazy import pipeline
            logger.info("RUN_PIPELINE_ON_START=true - executing Solana update pipeline") # log start
            run_solana_update_pipeline() # run Solana update once
        except TimeoutError as e: # predictor callback never arrived
            logger.error("Startup pipeline timed out: %s", e) # soft/hard fail below
            if os.getenv("EXIT_ON_PIPELINE_FAILURE", "false").lower() == "true": # hard fail opt-in
                sys.exit(1) # abort process
        except NotImplementedError as e: # unfinished steps
            logger.warning("Startup pipeline stopped: %s", e) # soft fail
        except Exception as e: # unexpected pipeline error
            logger.error("Startup pipeline failed: %s", e, exc_info=True) # log stack
            if os.getenv("EXIT_ON_PIPELINE_FAILURE", "false").lower() == "true": # hard fail opt-in
                sys.exit(1) # abort process

    app.run(
        host=host,
        port=port,
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true",
        threaded=True,
    ) # serve Flask API


##### run when executed directly #####

if __name__ == "__main__": # if this file is the program entrypoint...
    main() # start application_backend
