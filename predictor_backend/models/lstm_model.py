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

##### import third-party libraries #####

import torch # import torch for Tensor types in method stubs
import torch.nn as nn # import nn for Module / LSTM / Linear layers

##### import local modules #####

import config # import architecture defaults from Config





##################################################
############### LSTM PREDICTOR ###################
##################################################


########## LSTM PREDICTOR ##########

class LSTMPredictor(nn.Module): # class for dual-LSTM + dense time-series predictor (TF-parity arch)

    ########## INIT ##########

    def __init__(
        self,
        input_size: int = 1,
        hidden_size_1: int = None,
        hidden_size_2: int = None,
        dropout_rate: float = None,
        dense_size: int = None,
        sequence_length: int = None,
    ): # function to build LSTM(60)→Dropout→LSTM(120)→Dropout→Dense(20)→Dense(1)

        super(LSTMPredictor, self).__init__() # initialize nn.Module

        ##### use config defaults if not provided #####

        hidden_size_1 = hidden_size_1 or config.config.LSTM_HIDDEN_SIZE_1 # first LSTM width
        hidden_size_2 = hidden_size_2 or config.config.LSTM_HIDDEN_SIZE_2 # second LSTM width
        dropout_rate = dropout_rate or config.config.DROPOUT_RATE # dropout between stages
        dense_size = dense_size or config.config.DENSE_SIZE # dense layer width

        self.input_size = input_size # store input feature count
        self.hidden_size_1 = hidden_size_1 # store first hidden size
        self.hidden_size_2 = hidden_size_2 # store second hidden size
        self.sequence_length = sequence_length or config.config.SEQUENCE_LENGTH # lookback length

        ##### first LSTM layer #####

        self.lstm1 = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size_1,
            batch_first=True,
            num_layers=1
        ) # LSTM(60) matching TF arch

        ##### dropout after first LSTM #####

        self.dropout1 = nn.Dropout(dropout_rate) # Dropout(0.3)

        ##### second LSTM layer #####

        self.lstm2 = nn.LSTM(
            input_size=hidden_size_1,
            hidden_size=hidden_size_2,
            batch_first=True,
            num_layers=1
        ) # LSTM(120) matching TF arch

        ##### dropout after second LSTM #####

        self.dropout2 = nn.Dropout(dropout_rate) # Dropout(0.3)

        ##### dense layers #####

        self.dense1 = nn.Linear(hidden_size_2, dense_size) # Dense(20)
        self.dense2 = nn.Linear(dense_size, 1) # Dense(1) output

        ##### activation #####

        self.relu = nn.ReLU() # ReLU after first dense


    ########## FORWARD ##########

    def forward(self, x: torch.Tensor) -> torch.Tensor: # function for forward pass through dual-LSTM + dense layers

        ##### first LSTM #####

        lstm1_out, _ = self.lstm1(x) # (batch, seq, hidden_1)
        lstm1_out = self.dropout1(lstm1_out) # dropout after LSTM1

        ##### second LSTM #####

        lstm2_out, _ = self.lstm2(lstm1_out) # (batch, seq, hidden_2)
        lstm2_out = self.dropout2(lstm2_out) # dropout after LSTM2

        ##### take the last output from sequence #####

        lstm2_last = lstm2_out[:, -1, :] # (batch, hidden_2)

        ##### dense layers #####

        dense1_out = self.relu(self.dense1(lstm2_last)) # Dense(20) + ReLU
        output = self.dense2(dense1_out) # Dense(1)

        return output # (batch, 1)


    ########## PREDICT SEQUENCE ##########

    def predict_sequence(
        self,
        x: torch.Tensor,
        device: torch.device,
        num_predictions: int = 1,
    ) -> torch.Tensor: # function to iteratively roll forward N future predictions from an input window

        self.eval() # inference mode
        predictions = [] # collect step preds
        current_input = x.clone() # rolling window starts as input

        with torch.no_grad(): # no grad for iterative forecast
            for _ in range(num_predictions): # roll N steps
                pred = self.forward(current_input) # next-step prediction
                predictions.append(pred) # accumulate

                ##### update input sequence: remove first, add prediction #####

                current_input = torch.cat([
                    current_input[:, 1:, :],
                    pred.unsqueeze(1)
                ], dim=1) # slide window with new pred

        return torch.cat(predictions, dim=1) # (batch_size, num_predictions)
