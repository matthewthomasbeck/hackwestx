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

import logging # import logging for training progress messages
from typing import Tuple # import Tuple for prepare_data_with_step return type

##### import third-party libraries #####

import numpy as np # import numpy for sequence arrays
import torch # import torch for device / tensors
import torch.nn as nn # import nn for MSELoss
import torch.optim as optim # import optim for Adam

##### import local modules #####

import config # import training defaults (epochs/batch/sequence)
from models.lstm_model import LSTMPredictor # import LSTM to train





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### TRAINING HELPERS #################
##################################################


########## CREATE TRAINED MODEL ##########

def create_trained_model(
    trainX: np.ndarray,
    trainY: np.ndarray,
    device: torch.device,
    epochs: int = 80,
    batch_size: int = 8,
    sequence_length: int = None,
) -> LSTMPredictor: # function to train a fresh LSTM on sequences with Adam/MSE

    logger.info(f"Creating and training model... (epochs={epochs}, batch_size={batch_size})") # log train start

    ##### infer sequence length from data if not provided #####

    if sequence_length is None: # allow caller to omit
        sequence_length = trainX.shape[1] # use window width from trainX

    ##### convert numpy arrays to PyTorch tensors #####

    trainX_tensor = torch.FloatTensor(trainX).to(device) # sequences on device
    trainY_tensor = torch.FloatTensor(trainY).unsqueeze(1).to(device) # targets with feature dim

    ##### create model matching TensorFlow architecture #####

    model = LSTMPredictor(
        input_size=trainX.shape[2] if len(trainX.shape) > 2 else 1,
        sequence_length=sequence_length
    ) # fresh LSTM for this step
    model.to(device) # move to GPU/CPU

    ##### use Adam optimizer and MSE loss (matching TensorFlow) #####

    optimizer = optim.Adam(model.parameters()) # Adam
    criterion = nn.MSELoss() # MSE

    ##### training loop #####

    model.train() # train mode
    n_samples = len(trainX) # sample count
    n_batches = (n_samples + batch_size - 1) // batch_size # ceil division
    avg_loss = 0.0 # track last epoch avg

    for epoch in range(epochs): # epoch loop
        total_loss = 0.0 # accumulate batch losses

        ##### shuffle data each epoch #####

        indices = torch.randperm(n_samples).to(device) # random permutation
        trainX_shuffled = trainX_tensor[indices] # shuffled X
        trainY_shuffled = trainY_tensor[indices] # shuffled Y

        for batch_idx in range(n_batches): # batch loop
            start_idx = batch_idx * batch_size # batch start
            end_idx = min(start_idx + batch_size, n_samples) # batch end

            batch_X = trainX_shuffled[start_idx:end_idx] # mini-batch X
            batch_Y = trainY_shuffled[start_idx:end_idx] # mini-batch Y

            ##### forward pass #####

            optimizer.zero_grad() # clear grads
            predictions = model(batch_X) # forward
            loss = criterion(predictions, batch_Y) # MSE

            ##### backward pass #####

            loss.backward() # backprop
            optimizer.step() # Adam step

            total_loss += loss.item() # accumulate

        avg_loss = total_loss / n_batches # mean loss this epoch
        if (epoch + 1) % 20 == 0 or epoch == 0: # periodic log
            logger.debug(f"Epoch {epoch + 1}/{epochs}, Loss: {avg_loss:.6f}") # debug progress

    model.eval() # switch to eval for inference
    logger.info(f"Model training completed. Final loss: {avg_loss:.6f}") # log completion

    return model # trained LSTM


########## PREPARE DATA WITH STEP ##########

def prepare_data_with_step(
    data: np.ndarray,
    step: int,
    sequence_length: int = 7,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]: # function to build trainX/trainY/lastSequence shifted by future step

    if len(data) < sequence_length + step: # need window + future target
        raise ValueError(
            f"Data length ({len(data)}) must be at least {sequence_length + step}"
        ) # reject undersized series

    ##### create sequences where target is 'step' positions ahead #####

    X, y = [], [] # accumulate windows / targets
    max_start_idx = len(data) - sequence_length - step + 1 # last valid start

    for i in range(max_start_idx): # slide across series
        X.append(data[i:i + sequence_length]) # input window
        target_idx = i + sequence_length - 1 + step # target at end-of-window + step
        y.append(data[target_idx]) # future value

    trainX = np.array(X) # (n_samples, sequence_length)
    trainY = np.array(y) # (n_samples,)

    ##### get last sequence for future predictions #####

    lastSequence = data[-sequence_length:] # trailing lookback window

    ##### reshape trainX to add feature dimension #####

    trainX = trainX.reshape(trainX.shape[0], trainX.shape[1], 1) # (N, seq, 1)

    return trainX, trainY, lastSequence # windows, targets, last window
