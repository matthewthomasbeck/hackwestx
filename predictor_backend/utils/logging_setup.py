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

    pass # skeleton: create prediction_service logger; clear handlers; console (+ optional file); return logger
