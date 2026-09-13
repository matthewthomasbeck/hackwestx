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

import logging # import logging for logger factory
import sys # import sys for stdout StreamHandler
from pathlib import Path # import Path to ensure log file parent dirs
from typing import Optional # import Optional for optional level/file overrides

##### import local modules #####

import config # import LOG_LEVEL / LOG_FILE defaults





##################################################
############### LOGGING SETUP ####################
##################################################


########## SETUP LOGGING ##########

def setup_logging(
    log_level: Optional[str] = None,
    log_file: Optional[str] = None,
) -> logging.Logger: # function to configure prediction_service console/file logging from env

    level = log_level or config.config.LOG_LEVEL # use override or config default level
    log_file_path = log_file or config.config.LOG_FILE # use override or optional config file path

    ##### create logger #####

    logger = logging.getLogger("prediction_service") # named service logger shared across modules
    logger.setLevel(getattr(logging, level.upper(), logging.INFO)) # resolve level name to logging constant

    ##### clear existing handlers #####

    logger.handlers.clear() # avoid duplicate handlers on repeated setup

    ##### formatter #####

    formatter = logging.Formatter( # consistent timestamped log line format
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    ##### console handler #####

    console_handler = logging.StreamHandler(sys.stdout) # emit logs to stdout
    console_handler.setLevel(logging.DEBUG) # let logger level filter; handler accepts all
    console_handler.setFormatter(formatter) # apply shared formatter
    logger.addHandler(console_handler) # attach console handler

    ##### optional file handler #####

    if log_file_path: # only create file handler when a path is configured
        log_path = Path(log_file_path) # path object for parent mkdir
        log_path.parent.mkdir(parents=True, exist_ok=True) # ensure log directory exists
        file_handler = logging.FileHandler(log_file_path) # write logs to file
        file_handler.setLevel(logging.DEBUG) # accept all; logger level filters
        file_handler.setFormatter(formatter) # apply shared formatter
        logger.addHandler(file_handler) # attach file handler

    return logger # return configured prediction_service logger
