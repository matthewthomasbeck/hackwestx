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
from datetime import datetime, timedelta, timezone # import datetime for optional start/end bounds
from typing import Any, Dict, List, Optional # import typing helpers

##### import third-party libraries #####

import pandas as pd # import pandas for OHLCV frame normalization
import yfinance as yf # import yfinance for SOL-USD downloads
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
############### FRAME NORMALIZATION ##############
##################################################


########## FLATTEN COLUMNS ##########

def _flatten_columns(df): # function to collapse MultiIndex columns from yfinance into single-level names

    if not isinstance(df.columns, pd.MultiIndex): # already flat
        return df # unchanged

    # Prefer the price field level (Open/High/Low/Close/Volume) over ticker level
    level0 = [str(c).strip().lower() for c in df.columns.get_level_values(0)] # first level labels
    price_names = {"open", "high", "low", "close", "adj close", "volume"} # known OHLCV names
    if any(name in price_names for name in level0): # level 0 looks like OHLCV
        df = df.copy() # avoid mutating caller
        df.columns = level0 # use price field names
        return df # flattened

    level1 = [str(c).strip().lower() for c in df.columns.get_level_values(1)] # second level
    df = df.copy() # avoid mutating caller
    df.columns = level1 # use second level as columns
    return df # flattened


########## TO UTC TIMESTAMP ##########

def _to_utc_timestamp(value): # function to coerce an index/label value into timezone-aware UTC datetime

    ts = pd.Timestamp(value) # pandas timestamp
    if ts.tzinfo is None: # Yahoo daily bars are often tz-naive
        ts = ts.tz_localize("UTC") # treat as UTC midnight
    else: # already aware
        ts = ts.tz_convert("UTC") # normalize to UTC
    return ts.to_pydatetime() # plain datetime for Tiger / JSON





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

    logger.info(
        "Fetching Solana OHLCV via yfinance (ticker=%s period=%s interval=%s start=%s end=%s)",
        ticker,
        period,
        interval,
        start,
        end,
    ) # log fetch parameters

    download_kwargs = {
        "tickers": ticker,
        "interval": interval,
        "auto_adjust": True,
        "progress": False,
        "threads": False,
    } # shared yfinance options

    if start is not None or end is not None: # bounded window (incremental / custom)
        download_kwargs["start"] = start # inclusive start
        download_kwargs["end"] = end # exclusive end in yfinance
    else: # default rolling history
        download_kwargs["period"] = period # e.g. 2y

    df = yf.download(**download_kwargs) # download SOL OHLCV frame

    if df is None or df.empty: # Yahoo returned nothing
        logger.warning("yfinance returned empty frame for %s", ticker) # warn empty
        return [] # no rows

    df = _flatten_columns(df) # flatten MultiIndex if present
    df = df.rename(columns=lambda c: str(c).strip().lower()) # normalize column names

    required = ("open", "high", "low", "close") # minimum OHLCV fields
    missing = [col for col in required if col not in df.columns] # missing required cols
    if missing: # cannot normalize
        raise ValueError(f"yfinance frame missing columns {missing}; got {list(df.columns)}") # fail fast

    rows: List[Dict[str, Any]] = [] # Tiger-ready row list
    for idx, series in df.iterrows(): # walk each candle
        close_val = series.get("close") # close price
        if pd.isna(close_val): # skip incomplete bars
            continue # next candle

        volume_val = series.get("volume") # optional volume
        if pd.isna(volume_val): # missing volume
            volume_val = None # store NULL

        rows.append(
            {
                "time": _to_utc_timestamp(idx),
                "open": float(series["open"]),
                "high": float(series["high"]),
                "low": float(series["low"]),
                "close": float(close_val),
                "volume": float(volume_val) if volume_val is not None else None,
                "source": "yfinance",
            }
        ) # one normalized OHLCV row

    logger.info("Fetched %s SOL OHLCV rows from yfinance", len(rows)) # log count
    return rows # Tiger-ready rows


########## FETCH SOLANA SINCE ##########

def fetch_solana_since(last_time): # function to fetch only SOL bars after last Tiger timestamp (or full history)

    if last_time is None: # no prior Tiger data
        logger.info("No prior Tiger data - fetching full default history") # full backfill
        return fetch_solana_ohlcv() # default period/interval

    # Start one day after last stored bar so we don't re-download the same candle
    # (upsert is idempotent, but this keeps incremental pulls small)
    if isinstance(last_time, datetime): # datetime from Tiger
        start = last_time + timedelta(days=1) # next calendar day
    else: # date / string fallback
        start = pd.Timestamp(last_time).to_pydatetime() + timedelta(days=1) # coerce + step

    if start.tzinfo is None: # ensure aware start for logging / Yahoo
        start = start.replace(tzinfo=timezone.utc) # assume UTC

    logger.info("Fetching Solana OHLCV since %s (yfinance start=%s)", last_time, start) # incremental
    return fetch_solana_ohlcv(start=start) # bounded download
