############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

from typing import Any, Dict, Optional # import typing helpers





##################################################
############### MODULE STATE #####################
##################################################


########## CALLBACK PAYLOAD STORE ##########

_pending_prediction_result: Optional[Dict[str, Any]] = None # last predictor callback JSON





##################################################
############### CALLBACK RESULT STORE ############
##################################################


########## GET PENDING PREDICTION RESULT ##########

def get_pending_prediction_result(): # function to return last predictor callback payload if present

    return _pending_prediction_result # last callback JSON or None


########## SET PENDING PREDICTION RESULT ##########

def set_pending_prediction_result(payload): # function to save/clear predictor callback JSON for waiters

    global _pending_prediction_result # mutate module store
    _pending_prediction_result = payload # save callback JSON (or None to clear)


########## CLEAR PENDING PREDICTION RESULT ##########

def clear_pending_prediction_result(): # function to reset store before a new predict request

    set_pending_prediction_result(None) # wipe previous callback
