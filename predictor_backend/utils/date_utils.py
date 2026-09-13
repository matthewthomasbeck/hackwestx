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

import logging # import logging for unsupported-format warnings
import re # import re for YYYY-Q parsing
from datetime import datetime, timedelta # import datetime helpers for day/month increments
from typing import List # import List for future date return type

##### import third-party libraries #####

from dateutil.relativedelta import relativedelta # import relativedelta for month/quarter/year steps





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### DATE UTILITIES ###################
##################################################


########## PARSE DATE FORMAT ##########

def parse_date_format(date_str: str, format_str: str) -> datetime: # function to parse YYYY-Q / YYYY-MM / YYYY-MM-DD / YYYY labels

    ##### handle common formats #####

    if format_str == "YYYY-Q": # Format: "2023-Q4"
        match = re.match(r'(\d{4})-Q(\d)', date_str) # capture year and quarter
        if match: # valid quarter label
            year, quarter = int(match.group(1)), int(match.group(2)) # parse ints
            month = (quarter - 1) * 3 + 1 # first month of quarter
            return datetime(year, month, 1) # quarter start date
    elif format_str == "YYYY-MM": # Format: "2023-12"
        return datetime.strptime(date_str, "%Y-%m") # year-month
    elif format_str == "YYYY-MM-DD": # Format: "2023-12-31"
        return datetime.strptime(date_str, "%Y-%m-%d") # full calendar date
    elif format_str == "YYYY": # Format: "2023"
        return datetime(int(date_str), 1, 1) # year start

    ##### try to parse as ISO format #####

    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00')) # ISO / Zulu fallback
    except Exception: # unsupported combination
        logger.warning(f"Could not parse date '{date_str}' with format '{format_str}'") # log failure
        raise ValueError(f"Unsupported date format: {format_str}") # surface clear error


########## FORMAT DATE ##########

def format_date(date: datetime, format_str: str) -> str: # function to format datetime back into the series x-axis style

    if format_str == "YYYY-Q": # quarter label
        quarter = (date.month - 1) // 3 + 1 # 1..4
        return f"{date.year}-Q{quarter}" # e.g. 2023-Q4
    elif format_str == "YYYY-MM": # month label
        return date.strftime("%Y-%m") # e.g. 2023-12
    elif format_str == "YYYY-MM-DD": # day label
        return date.strftime("%Y-%m-%d") # e.g. 2023-12-31
    elif format_str == "YYYY": # year label
        return str(date.year) # e.g. 2023
    else: # unknown format
        return date.isoformat() # ISO fallback string


########## INCREMENT DATE ##########

def increment_date(date: datetime, format_str: str, steps: int = 1) -> datetime: # function to advance a date by format-appropriate steps

    if format_str == "YYYY-Q": # increment by quarters
        return date + relativedelta(months=3 * steps) # +3 months per step
    elif format_str == "YYYY-MM": # increment by months
        return date + relativedelta(months=steps) # +1 month per step
    elif format_str == "YYYY-MM-DD": # increment by days
        return date + timedelta(days=steps) # +1 day per step
    elif format_str == "YYYY": # increment by years
        return date + relativedelta(years=steps) # +1 year per step
    else: # default to days
        return date + timedelta(days=steps) # day fallback


########## GENERATE FUTURE DATES ##########

def generate_future_dates(
    last_date_str: str,
    date_format: str,
    num_predictions: int,
) -> List[str]: # function to build future x labels after the last series timestamp

    last_date = parse_date_format(last_date_str, date_format) # parse last historical stamp
    future_dates = [] # accumulate future labels

    for i in range(1, num_predictions + 1): # steps 1..N
        future_date = increment_date(last_date, date_format, steps=i) # advance from last
        future_dates.append(format_date(future_date, date_format)) # format as series style

    return future_dates # list of future x labels
