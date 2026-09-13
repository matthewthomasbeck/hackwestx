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

import logging # import logging for Tiger DB messages
import os # import os for DATABASE_URL / TIGER_* env vars
from contextlib import contextmanager # import contextmanager for connection lifecycle
from datetime import datetime # import datetime for OHLCV/prediction timestamps
from pathlib import Path # import Path to resolve application_backend/.env regardless of cwd
from typing import Any, Dict, List, Optional # import typing helpers
from urllib.parse import quote_plus # import quote_plus for password URL encoding

##### import third-party libraries #####

import psycopg # import psycopg v3 for Postgres / Timescale connections
from dotenv import load_dotenv # import dotenv to load Tiger credentials
from psycopg.rows import dict_row # import dict_row for dict-shaped query results

##### load environment #####

# Always load application_backend/.env (not whatever directory the process was started from)
load_dotenv(Path(__file__).resolve().parent.parent / ".env")





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### TIGER CONNECTION #################
##################################################


########## URI HAS PASSWORD ##########

def _uri_has_password(database_url): # function to detect whether a Postgres URI includes a non-empty password

    if "@" not in database_url: # not a standard URI
        return False # treat as missing
    userinfo = database_url.split("@", 1)[0] # scheme://user:pass
    if "://" in userinfo: # strip scheme
        userinfo = userinfo.split("://", 1)[1] # user:pass or user
    if ":" not in userinfo: # postgres://user@host — no password slot
        return False # missing
    password = userinfo.split(":", 1)[1] # may be empty
    return bool(password) # True only when non-empty


########## INJECT PASSWORD INTO URI ##########

def _inject_password(database_url, password): # function to insert/replace userinfo password in a Postgres URI

    if "@" not in database_url: # unexpected shape
        return database_url # leave unchanged
    head, tail = database_url.split("@", 1) # scheme://userinfo  |  host...
    if "://" not in head: # unexpected
        return database_url # leave unchanged
    scheme, userinfo = head.split("://", 1) # postgres  |  user:pass
    user = userinfo.split(":", 1)[0] if userinfo else "tsdbadmin" # keep username
    return f"{scheme}://{quote_plus(user)}:{quote_plus(password)}@{tail}" # rebuilt URI


########## BUILD DATABASE URL ##########

def _database_url(): # function to resolve DATABASE_URL or compose it from TIGER_* pieces

    database_url = (os.getenv("DATABASE_URL") or "").strip() # may be set from template/CLI
    password = os.getenv("TIGER_PASSWORD") or "" # dedicated password var

    if database_url: # URI present — may still lack a password
        if _uri_has_password(database_url): # complete URI
            return database_url # use as-is
        if password.strip(): # fill from TIGER_PASSWORD
            logger.info("DATABASE_URL missing password — injecting TIGER_PASSWORD") # no secret logged
            return _inject_password(database_url, password) # patched URI
        raise ValueError(
            "DATABASE_URL has no password and TIGER_PASSWORD is empty — "
            "set TIGER_PASSWORD in application_backend/.env "
            "(quote it if it contains # or spaces)"
        ) # fail clear

    host = (os.getenv("TIGER_HOST") or "").strip() # Tiger host
    port = (os.getenv("TIGER_PORT") or "5432").strip() # default Postgres port
    db = (os.getenv("TIGER_DB") or "tsdb").strip() # default Timescale db
    user = (os.getenv("TIGER_USER") or "tsdbadmin").strip() # default admin user
    sslmode = (os.getenv("TIGER_SSLMODE") or "require").strip() # SSL mode
    if not host: # need host or DATABASE_URL
        raise ValueError("DATABASE_URL or TIGER_HOST must be set") # fail fast
    if not password.strip(): # Tiger always requires a password
        raise ValueError(
            "TIGER_PASSWORD is empty — set it in application_backend/.env "
            "(quote it if it contains # or spaces)"
        ) # fail fast before fe_sendauth

    return (
        f"postgres://{quote_plus(user)}:{quote_plus(password)}"
        f"@{host}:{port}/{db}?sslmode={sslmode}"
    ) # composed connection URI with encoded credentials


########## GET CONNECTION ##########

def get_connection(): # function to open a Postgres/Timescale connection to Tiger Cloud

    database_url = _database_url() # resolve URI
    logger.debug("Opening Tiger Cloud connection") # log intent (no secrets)
    return psycopg.connect(database_url, row_factory=dict_row) # live connection


########## CONNECTION CONTEXT ##########

@contextmanager
def _cursor(): # function to yield a dict-row cursor and commit/rollback safely

    conn = get_connection() # open connection
    try: # manage transaction
        with conn.cursor() as cur: # open cursor
            yield cur # caller runs SQL
        conn.commit() # persist successful work
    except Exception: # any failure
        conn.rollback() # undo partial writes
        raise # re-raise for caller
    finally: # always close
        conn.close() # release connection





##################################################
############### SOL OHLCV (REAL PRICES) ##########
##################################################


########## GET LATEST OHLCV TIME ##########

def get_latest_ohlcv_time(): # function to return MAX(time) from sol_ohlcv, or None if empty

    logger.info("Fetching latest OHLCV timestamp from sol_ohlcv") # log query intent
    with _cursor() as cur: # open cursor
        cur.execute("SELECT MAX(time) AS max_time FROM sol_ohlcv") # latest bar
        row = cur.fetchone() # one result
    if not row or row.get("max_time") is None: # empty table
        return None # no prior data
    return row["max_time"] # timezone-aware datetime from Postgres


########## UPSERT OHLCV ##########

def upsert_ohlcv(rows): # function to insert/upsert real SOL OHLCV rows into sol_ohlcv

    if not rows: # nothing to write
        logger.info("No OHLCV rows to upsert") # skip
        return 0 # zero written

    logger.info("Upserting %s OHLCV rows into sol_ohlcv", len(rows)) # log write count

    # Requires UNIQUE (time) — see ensure_schema() / LLM_ADVICE SQL + unique index
    sql = """
        INSERT INTO sol_ohlcv (time, open, high, low, close, volume, source)
        VALUES (%(time)s, %(open)s, %(high)s, %(low)s, %(close)s, %(volume)s, %(source)s)
        ON CONFLICT (time) DO UPDATE SET
            open = EXCLUDED.open,
            high = EXCLUDED.high,
            low = EXCLUDED.low,
            close = EXCLUDED.close,
            volume = EXCLUDED.volume,
            source = EXCLUDED.source
    """ # idempotent candle upsert

    payloads = [] # normalized bind params
    for row in rows: # prepare each row
        payloads.append(
            {
                "time": row["time"],
                "open": row["open"],
                "high": row["high"],
                "low": row["low"],
                "close": row["close"],
                "volume": row.get("volume"),
                "source": row.get("source") or "yfinance",
            }
        ) # one bind dict

    with _cursor() as cur: # open cursor
        cur.executemany(sql, payloads) # batch upsert
        written = cur.rowcount if cur.rowcount is not None and cur.rowcount >= 0 else len(payloads) # best-effort count

    logger.info("Upserted OHLCV rows (reported=%s requested=%s)", written, len(payloads)) # log result
    return len(payloads) # number of rows attempted


########## READ OHLCV ##########

def read_ohlcv(start=None, end=None): # function to read real SOL prices from sol_ohlcv as JSON-ready payload

    logger.info("Reading OHLCV from sol_ohlcv (start=%s end=%s)", start, end) # log read

    clauses = [] # WHERE fragments
    params: Dict[str, Any] = {} # bind params
    if start is not None: # lower bound
        clauses.append("time >= %(start)s") # inclusive start
        params["start"] = start # bind
    if end is not None: # upper bound
        clauses.append("time <= %(end)s") # inclusive end
        params["end"] = end # bind

    where = f"WHERE {' AND '.join(clauses)}" if clauses else "" # optional filter
    sql = f"""
        SELECT time, open, high, low, close, volume, source
        FROM sol_ohlcv
        {where}
        ORDER BY time ASC
    """ # full series read

    with _cursor() as cur: # open cursor
        cur.execute(sql, params) # run query
        db_rows = cur.fetchall() # all matching candles

    series = [] # JSON-ready points
    for row in db_rows: # normalize timestamps to ISO
        ts = row["time"] # timestamptz
        series.append(
            {
                "time": ts.isoformat() if isinstance(ts, datetime) else str(ts),
                "open": float(row["open"]),
                "high": float(row["high"]),
                "low": float(row["low"]),
                "close": float(row["close"]),
                "volume": float(row["volume"]) if row.get("volume") is not None else None,
                "source": row.get("source"),
            }
        ) # one series point

    return {"asset": "SOL", "series": series} # predictor/frontend shape




##################################################
############### SOL PREDICTIONS ##################
##################################################


########## UPSERT PREDICTIONS ##########

def upsert_predictions(rows, model_version="bigru-attn-v1"): # function to write predictor output into sol_predictions

    if not rows: # nothing to write
        logger.info("No prediction rows to upsert") # skip
        return 0 # zero written

    logger.info(
        "Upserting %s prediction rows into sol_predictions (model=%s)",
        len(rows),
        model_version,
    ) # log write count

    sql = """
        INSERT INTO sol_predictions (time, predicted_close, model_version)
        VALUES (%(time)s, %(predicted_close)s, %(model_version)s)
        ON CONFLICT (time) DO UPDATE SET
            predicted_close = EXCLUDED.predicted_close,
            model_version = EXCLUDED.model_version,
            created_at = NOW()
    """ # idempotent forecast upsert

    payloads = [] # bind params
    for row in rows: # prepare each forecast
        payloads.append(
            {
                "time": row["time"],
                "predicted_close": row["predicted_close"],
                "model_version": row.get("model_version") or model_version,
            }
        ) # one bind dict

    with _cursor() as cur: # open cursor
        cur.executemany(sql, payloads) # batch upsert

    return len(payloads) # rows attempted


########## READ PREDICTIONS ##########

def read_predictions(start=None, end=None): # function to read predicted SOL prices from sol_predictions

    logger.info("Reading predictions from sol_predictions (start=%s end=%s)", start, end) # log

    clauses = [] # WHERE fragments
    params: Dict[str, Any] = {} # bind params
    if start is not None: # lower bound
        clauses.append("time >= %(start)s") # inclusive
        params["start"] = start # bind
    if end is not None: # upper bound
        clauses.append("time <= %(end)s") # inclusive
        params["end"] = end # bind

    where = f"WHERE {' AND '.join(clauses)}" if clauses else "" # optional filter
    sql = f"""
        SELECT time, predicted_close, model_version, created_at
        FROM sol_predictions
        {where}
        ORDER BY time ASC
    """ # forecast read

    with _cursor() as cur: # open cursor
        cur.execute(sql, params) # run query
        db_rows = cur.fetchall() # all matching forecasts

    series = [] # JSON-ready points
    for row in db_rows: # normalize
        ts = row["time"] # forecast-for time
        created = row.get("created_at") # write time
        series.append(
            {
                "time": ts.isoformat() if isinstance(ts, datetime) else str(ts),
                "predicted_close": float(row["predicted_close"]),
                "model_version": row.get("model_version"),
                "created_at": created.isoformat() if isinstance(created, datetime) else created,
            }
        ) # one forecast point

    return {"asset": "SOL", "series": series} # frontend shape


########## READ MARKET BUNDLE ##########

def read_market_bundle(forecast_days=None): # function to compose real OHLCV + forward predictions for frontend

    logger.info("Building market bundle (forecast_days=%s)", forecast_days) # log compose
    real = read_ohlcv() # full real series
    predictions = read_predictions() # full forecast series

    if forecast_days is not None and predictions.get("series"): # optional horizon trim
        predictions = {
            "asset": predictions.get("asset", "SOL"),
            "series": predictions["series"][: int(forecast_days)],
        } # keep first N forecasts

    return {
        "real": real,
        "predictions": predictions,
        "forecast_days": forecast_days,
    } # combined bundle





##################################################
############### SCHEMA HELPERS ###################
##################################################


########## ENSURE SCHEMA ##########

def ensure_schema(): # function to create sol_ohlcv / sol_predictions hypertables if missing

    logger.info("Ensuring Tiger sol_ohlcv / sol_predictions schema") # log DDL intent

    table_ddl = """
        CREATE TABLE IF NOT EXISTS sol_ohlcv (
          time        TIMESTAMPTZ       NOT NULL,
          open        DOUBLE PRECISION  NOT NULL,
          high        DOUBLE PRECISION  NOT NULL,
          low         DOUBLE PRECISION  NOT NULL,
          close       DOUBLE PRECISION  NOT NULL,
          volume      DOUBLE PRECISION,
          source      TEXT              DEFAULT 'yfinance',
          PRIMARY KEY (time)
        );

        CREATE TABLE IF NOT EXISTS sol_predictions (
          time             TIMESTAMPTZ       NOT NULL,
          predicted_close  DOUBLE PRECISION  NOT NULL,
          model_version    TEXT              NOT NULL DEFAULT 'bigru-attn-v1',
          created_at       TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
          PRIMARY KEY (time)
        );
    """ # base tables with PK(time) for upserts

    with _cursor() as cur: # create base tables
        cur.execute(table_ddl) # IF NOT EXISTS
        # If tables were created earlier without PK (LLM_ADVICE paste), unique indexes
        # still enable ON CONFLICT (time) upserts.
        cur.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS sol_ohlcv_time_uidx ON sol_ohlcv (time)"
        ) # upsert target
        cur.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS sol_predictions_time_uidx ON sol_predictions (time)"
        ) # upsert target

    # Convert to hypertables in separate transactions so a miss does not poison DDL
    for table in ("sol_ohlcv", "sol_predictions"): # each table independently
        try: # Timescale-specific
            with _cursor() as cur: # fresh txn
                cur.execute(
                    "SELECT create_hypertable(%s, by_range('time'), if_not_exists => TRUE)",
                    (table,),
                ) # promote to hypertable
        except Exception as exc: # already hypertable / extension missing / plan limits
            logger.warning("create_hypertable(%s) skipped: %s", table, exc) # non-fatal

    logger.info("Tiger schema ensure finished") # done
