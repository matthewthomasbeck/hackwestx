############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for postprocess diagnostics
from typing import List, Tuple # import typing helpers

##### import third-party libraries #####

import numpy as np # import numpy for prediction arrays
import torch # import torch for model output tensors
from sklearn.preprocessing import MinMaxScaler # import scaler for denormalization





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### POSTPROCESSING ###################
##################################################


########## PROCESS MODEL OUTPUTS ##########

def process_model_outputs(
    predictions: torch.Tensor,
    scaler: MinMaxScaler,
) -> np.ndarray: # function to move preds to CPU numpy and inverse MinMax scale

    ##### move to CPU and convert to numpy #####

    if isinstance(predictions, torch.Tensor): # handle torch tensors
        predictions_np = predictions.cpu().numpy() # detach to host numpy
    else: # already array-like
        predictions_np = np.array(predictions) # coerce to ndarray

    ##### flatten if needed #####

    if predictions_np.ndim > 1: # collapse batch/feature dims
        predictions_np = predictions_np.flatten() # 1D prediction vector

    ##### denormalize #####

    denormalized = scaler.inverse_transform(predictions_np.reshape(-1, 1)).flatten() # inverse MinMax

    return denormalized # original-scale predictions


########## GENERATE FITTED PREDICTIONS ##########

def generate_fitted_predictions(
    model,
    sequences: np.ndarray,
    device: torch.device,
    scaler: MinMaxScaler,
) -> np.ndarray: # function to run model over all historical sequences and denormalize

    model.eval() # inference mode
    fitted_preds = [] # collect per-window preds

    with torch.no_grad(): # no grad for fitted pass
        for seq in sequences: # one historical window at a time
            seq_tensor = torch.FloatTensor(seq).unsqueeze(0).to(device) # add batch dim on device
            pred = model(seq_tensor) # forward pass
            fitted_preds.append(pred.cpu().numpy().flatten()[0]) # first scalar pred

    ##### denormalize #####

    fitted_array = np.array(fitted_preds) # stack fitted values
    denormalized = scaler.inverse_transform(fitted_array.reshape(-1, 1)).flatten() # inverse MinMax

    return denormalized # historical fitted predictions


########## COMBINE PREDICTIONS ##########

def combine_predictions(
    fitted_predictions: np.ndarray,
    future_predictions: np.ndarray,
) -> np.ndarray: # function to concatenate fitted historical and future prediction arrays

    return np.concatenate([fitted_predictions, future_predictions]) # fitted then future
