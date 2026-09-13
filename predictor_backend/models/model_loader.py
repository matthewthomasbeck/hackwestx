############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for load/device diagnostics
from pathlib import Path # import Path for checkpoint existence checks
from typing import Optional # import Optional for unloaded model state

##### import third-party libraries #####

import torch # import torch for device selection and checkpoint load

##### import local modules #####

import config # import MODEL_PATH and related settings
from models.lstm_model import LSTMPredictor # import LSTM architecture class





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### MODEL MANAGER ####################
##################################################


########## MODEL MANAGER ##########

class ModelManager: # class to manage LSTM load, device selection, and inference access

    ########## INIT ##########

    def __init__(self, model_path: Optional[str] = None): # function to store checkpoint path and pick CUDA/CPU device

        self.model_path = model_path or config.config.MODEL_PATH # checkpoint path from arg or config
        self.device = self._get_device() # select CUDA or CPU
        self.model: Optional[LSTMPredictor] = None # lazy-loaded model
        logger.info(f"Model manager initialized. Device: {self.device}") # log device choice


    ########## GET DEVICE ##########

    def _get_device(self) -> torch.device: # function to choose CUDA when available else CPU

        if torch.cuda.is_available(): # prefer GPU when present
            device = torch.device("cuda") # CUDA device
            logger.info(f"Using GPU: {torch.cuda.get_device_name(0)}") # log GPU name
            logger.info(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB") # log VRAM
        else: # no CUDA
            device = torch.device("cpu") # fall back to CPU
            logger.info("CUDA not available, using CPU") # log CPU fallback
        return device # selected device


    ########## LOAD MODEL ##########

    def load_model(self) -> LSTMPredictor: # function to load checkpoint weights or construct a fresh BiGRU-attention model

        if self.model is not None: # already loaded
            return self.model # reuse in-memory model

        model_path = Path(self.model_path) # path to checkpoint
        if not model_path.exists(): # missing weights file (normal: train per request)
            logger.info(
                "No checkpoint at %s. Initializing BiGRU-attention architecture "
                "(weights are trained per prediction request)",
                model_path,
            ) # expected path when no saved weights
            self.model = LSTMPredictor() # fresh untrained BiGRU-attention arch
            self.model.to(self.device) # place on device
            return self.model # return new model

        try:
            logger.info("Loading BiGRU-attention checkpoint from %s", model_path) # log load attempt
            checkpoint = torch.load(model_path, map_location=self.device) # load to device

            ##### handle different checkpoint formats #####

            if isinstance(checkpoint, dict): # dict checkpoint
                if 'model_state_dict' in checkpoint: # common key
                    state_dict = checkpoint['model_state_dict'] # extract weights
                elif 'state_dict' in checkpoint: # alternate key
                    state_dict = checkpoint['state_dict'] # extract weights
                else: # assume raw state_dict
                    state_dict = checkpoint # use as-is
            else: # non-dict checkpoint
                state_dict = checkpoint # use as-is

            ##### create model and load weights #####

            self.model = LSTMPredictor() # construct BiGRU-attention arch
            self.model.load_state_dict(state_dict) # apply weights
            self.model.to(self.device) # place on device
            self.model.eval() # inference mode

            logger.info("BiGRU-attention checkpoint loaded successfully") # success
            return self.model # loaded model

        except Exception as e: # corrupt / incompatible checkpoint
            logger.error("Error loading BiGRU-attention checkpoint: %s", e) # log error
            logger.info("Initializing fresh BiGRU-attention architecture instead") # fallback path
            self.model = LSTMPredictor() # fresh model
            self.model.to(self.device) # place on device
            return self.model # return fallback


    ########## GET MODEL ##########

    def get_model(self) -> LSTMPredictor: # function to return loaded model, loading on first access

        if self.model is None: # lazy load
            self.load_model() # load or create
        return self.model # in-memory model


    ########## GET DEVICE ##########

    def get_device(self) -> torch.device: # function to return the active torch device

        return self.device # CUDA or CPU


    ########## IS LOADED ##########

    def is_loaded(self) -> bool: # function to report whether a model instance is in memory

        return self.model is not None # True when model exists
