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
############### FORMATTER ########################
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





##################################################
############### LOGGING SETUP ####################
##################################################


########## SETUP LOGGING ##########

def setup_logging(
    log_level: Optional[str] = None,
    log_file: Optional[str] = None,
) -> logging.Logger: # function to configure root console/file logging from env

    level_name = log_level or config.config.LOG_LEVEL # use override or config default level
    level = getattr(logging, level_name.upper(), logging.INFO) # resolve level name
    log_file_path = log_file or config.config.LOG_FILE # use override or optional config file path

    root = logging.getLogger() # configure root so all __name__ loggers inherit
    root.setLevel(level) # apply level

    formatter = ModulePathFormatter(
        "%(asctime)s - %(levelname)s (%(module_path)s): %(message)s"
    ) # timestamp - LEVEL (path/file.py): message

    ##### console handler #####

    if not any(isinstance(h, logging.StreamHandler) and not isinstance(h, logging.FileHandler) for h in root.handlers):
        console_handler = logging.StreamHandler(sys.stdout) # emit logs to stdout
        console_handler.setLevel(level) # match root level
        console_handler.setFormatter(formatter) # apply shared formatter
        root.addHandler(console_handler) # attach console handler
    else:
        for handler in root.handlers: # refresh format on existing console handlers
            if isinstance(handler, logging.StreamHandler) and not isinstance(handler, logging.FileHandler):
                handler.setFormatter(formatter) # keep format consistent on re-setup
                handler.setLevel(level) # keep level consistent

    ##### optional file handler #####

    if log_file_path: # only create file handler when a path is configured
        log_path = Path(log_file_path) # path object for parent mkdir
        log_path.parent.mkdir(parents=True, exist_ok=True) # ensure log directory exists
        abs_path = str(log_path.resolve()) # absolute for dedupe
        if not any(
            isinstance(h, logging.FileHandler)
            and getattr(h, "baseFilename", None) == abs_path
            for h in root.handlers
        ): # avoid duplicate file handlers for same path
            file_handler = logging.FileHandler(log_file_path) # write logs to file
            file_handler.setLevel(level) # match root level
            file_handler.setFormatter(formatter) # apply shared formatter
            root.addHandler(file_handler) # attach file handler

    return logging.getLogger(__name__) # return setup module logger
