############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for preprocess diagnostics
from typing import Dict, List, Optional, Tuple # import typing helpers

##### import third-party libraries #####

import numpy as np # import numpy for value arrays / sequences
from sklearn.preprocessing import MinMaxScaler # import MinMaxScaler for 0–1 normalization





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### PREPROCESSING ####################
##################################################


########## EXTRACT TIME SERIES DATA ##########

def extract_time_series_data(series_data: List[Dict]) -> Tuple[List[str], np.ndarray]: # function to extract/sort x labels and y floats from series points

    ##### extract x and y values #####

    times = [item['x'] for item in series_data] # collect time labels
    values = [float(item['y']) for item in series_data] # collect numeric values

    ##### sort by time #####

    sorted_pairs = sorted(zip(times, values), key=lambda x: x[0]) # sort (time, value) by time
    sorted_times, sorted_values = zip(*sorted_pairs) # unzip into parallel sequences

    return list(sorted_times), np.array(sorted_values, dtype=np.float32) # return times list + float32 values


########## CREATE SEQUENCES ##########

def create_sequences(
    data: np.ndarray,
    sequence_length: int = 7,
) -> Tuple[np.ndarray, np.ndarray]: # function to build sliding trainX/trainY windows of length sequence_length

    if len(data) < sequence_length + 1: # need at least one full window plus a target
        raise ValueError(
            f"Data length ({len(data)}) must be at least {sequence_length + 1}"
        ) # reject undersized series

    X, y = [], [] # accumulate windows and targets
    for i in range(len(data) - sequence_length): # slide across series
        X.append(data[i:i + sequence_length]) # input window
        y.append(data[i + sequence_length]) # next-step target

    return np.array(X), np.array(y) # return trainX / trainY arrays


########## NORMALIZE DATA ##########

def normalize_data(data: np.ndarray) -> Tuple[np.ndarray, MinMaxScaler]: # function to fit MinMaxScaler(0,1) and return normalized values

    scaler = MinMaxScaler(feature_range=(0, 1)) # scale values into [0, 1]
    data_reshaped = data.reshape(-1, 1) # sklearn expects 2D
    normalized = scaler.fit_transform(data_reshaped).flatten() # fit + transform then flatten
    return normalized, scaler # return normalized series and fitted scaler


########## DENORMALIZE DATA ##########

def denormalize_data(
    data: np.ndarray,
    scaler: MinMaxScaler,
) -> np.ndarray: # function to inverse-transform normalized values with a fitted scaler

    data_reshaped = data.reshape(-1, 1) # sklearn expects 2D
    denormalized = scaler.inverse_transform(data_reshaped).flatten() # inverse then flatten
    return denormalized # return original-scale values


########## PREPARE PREDICTION INPUT ##########

def prepare_prediction_input(
    data: np.ndarray,
    sequence_length: int = 7,
) -> np.ndarray: # function to reshape the last sequence_length values as (1, seq, 1)

    if len(data) < sequence_length: # need a full lookback window
        raise ValueError(
            f"Data length ({len(data)}) must be at least {sequence_length}"
        ) # reject undersized series

    last_sequence = data[-sequence_length:] # take trailing window
    return last_sequence.reshape(1, sequence_length, 1) # batch, seq, feature


########## PREPARE BATCH SEQUENCES ##########

def prepare_batch_sequences(
    data_list: List[np.ndarray],
    sequence_length: int = 7,
) -> List[np.ndarray]: # function to prepare last-window inputs for multiple series

    sequences = [] # collect per-series inputs
    for data in data_list: # map prepare_prediction_input over each series
        seq = prepare_prediction_input(data, sequence_length) # last-window tensor shape
        sequences.append(seq) # accumulate
    return sequences # return list of (1, seq, 1) arrays
