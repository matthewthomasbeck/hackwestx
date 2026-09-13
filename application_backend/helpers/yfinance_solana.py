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

import logging # import logging for yfinance fetch messages
import os # import os for ticker/period/interval defaults
from datetime import datetime # import datetime for optional start/end bounds
from typing import Any, Dict, List, Optional # import typing helpers

##### import third-party libraries #####

from dotenv import load_dotenv # import dotenv to load yfinance-related env vars

##### load environment #####

load_dotenv() # load YFINANCE_* defaults if present





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER / DEFAULTS ##########

logger = logging.getLogger(__name__) # create module logger

DEFAULT_TICKER = os.getenv("YFINANCE_SOL_TICKER", "SOL-USD") # default Yahoo ticker for Solana
DEFAULT_INTERVAL = os.getenv("YFINANCE_INTERVAL", "1d") # default candle interval
DEFAULT_PERIOD = os.getenv("YFINANCE_PERIOD", "2y") # default history window when no start/end





##################################################
############### YFINANCE SOLANA FETCH ############
##################################################


########## FETCH SOLANA OHLCV ##########

def fetch_solana_ohlcv( # function to download SOL OHLCV from Yahoo Finance and normalize Tiger-ready rows
        ticker=DEFAULT_TICKER,
        period=DEFAULT_PERIOD,
        interval=DEFAULT_INTERVAL,
        start=None,
        end=None
):

    pass # skeleton: yfinance.download → list of {time,open,high,low,close,volume,source}


########## FETCH SOLANA SINCE ##########

def fetch_solana_since(last_time): # function to fetch only SOL bars after last Tiger timestamp (or full history)

    pass # skeleton: if last_time is None fetch full history else incremental from last_time
