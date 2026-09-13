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
import torch.nn as nn # import nn for Module / GRU / Linear / LayerNorm
import torch.nn.functional as F # import F for softmax attention weights

##### import local modules #####

import config # import architecture defaults from Config





##################################################
############### LSTM PREDICTOR ###################
##################################################


########## LSTM PREDICTOR ##########

class LSTMPredictor(nn.Module): # class for BiGRU + temporal attention time-series predictor

    ########## INIT ##########

    def __init__(
        self,
        input_size: int = 1,
        gru_hidden_size: int = None,
        gru_num_layers: int = None,
        dropout_rate: float = None,
        dense_size: int = None,
        sequence_length: int = None,
    ): # function to build BiGRU→LayerNorm→Attention→Dense→Dense(1)

        super(LSTMPredictor, self).__init__() # initialize nn.Module

        ##### use config defaults if not provided #####

        gru_hidden_size = gru_hidden_size or config.config.GRU_HIDDEN_SIZE # unidirectional GRU width
        gru_num_layers = gru_num_layers or config.config.GRU_NUM_LAYERS # stacked GRU depth
        dropout_rate = dropout_rate if dropout_rate is not None else config.config.DROPOUT_RATE # stage dropout
        dense_size = dense_size or config.config.DENSE_SIZE # penultimate dense width

        self.input_size = input_size # store input feature count
        self.gru_hidden_size = gru_hidden_size # store GRU hidden size
        self.sequence_length = sequence_length or config.config.SEQUENCE_LENGTH # lookback length
        self.bidirectional_size = gru_hidden_size * 2 # concat forward+backward states

        ##### stacked bidirectional GRU #####

        self.gru = nn.GRU(
            input_size=input_size,
            hidden_size=gru_hidden_size,
            num_layers=gru_num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout_rate if gru_num_layers > 1 else 0.0,
        ) # BiGRU stack over the lookback window

        ##### normalize BiGRU outputs before attention #####

        self.layer_norm = nn.LayerNorm(self.bidirectional_size) # stabilize BiGRU features
        self.dropout = nn.Dropout(dropout_rate) # dropout after norm

        ##### learned temporal attention over the sequence #####

        self.attention = nn.Linear(self.bidirectional_size, 1) # score each timestep

        ##### dense head #####

        self.dense1 = nn.Linear(self.bidirectional_size, dense_size) # Dense(dense_size)
        self.dense2 = nn.Linear(dense_size, 1) # Dense(1) output
        self.gelu = nn.GELU() # GELU after first dense


    ########## FORWARD ##########

    def forward(self, x: torch.Tensor) -> torch.Tensor: # function for BiGRU + attention forward pass

        ##### bidirectional GRU over the full window #####

        gru_out, _ = self.gru(x) # (batch, seq, hidden*2)
        gru_out = self.layer_norm(gru_out) # normalize across features
        gru_out = self.dropout(gru_out) # regularize

        ##### temporal attention pooling #####

        attn_scores = self.attention(gru_out).squeeze(-1) # (batch, seq)
        attn_weights = F.softmax(attn_scores, dim=1).unsqueeze(-1) # (batch, seq, 1)
        context = torch.sum(gru_out * attn_weights, dim=1) # (batch, hidden*2)

        ##### dense head #####

        dense1_out = self.gelu(self.dense1(context)) # Dense + GELU
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
