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

import os # import os for environment variable access
from typing import Optional # import Optional for nullable config fields

##### import third-party libraries #####

from dotenv import load_dotenv # import dotenv to load .env into process env

##### load environment #####

load_dotenv() # load predictor_backend/.env values





##################################################
############### CONFIGURATION ####################
##################################################


########## CONFIG ##########

class Config: # class to hold prediction service settings from environment

    ##### API Authentication (interim shared secret from Time_Series_Predictor) #####

    PREDICTION_SERVICE_KEY: str = os.getenv("PREDICTION_SERVICE_KEY", "") # interim Bearer shared secret

    ##### Auth0 M2M verification (application_backend → predictor_backend) #####

    AUTH0_DOMAIN: str = os.getenv("AUTH0_DOMAIN", "") # Auth0 tenant domain for JWKS
    AUTH0_AUDIENCE: str = os.getenv(
        "AUTH0_AUDIENCE",
        "https://predictor.soothsayer.hackwestx",
    ) # expected JWT audience for M2M tokens
    AUTH0_ISSUER: str = os.getenv("AUTH0_ISSUER", "") # expected JWT issuer URL

    ##### Worker Configuration #####

    NUM_GPU_WORKERS: int = int(os.getenv("NUM_GPU_WORKERS", "1")) # count of GPU inference workers
    NUM_CPU_WORKERS: int = int(os.getenv("NUM_CPU_WORKERS", "4")) # count of CPU helper workers
    BATCH_SIZE: int = int(os.getenv("BATCH_SIZE", "32")) # general inference batch size hint

    ##### Model Configuration #####

    MODEL_PATH: str = os.getenv("MODEL_PATH", "./models/lstm_model.pth") # checkpoint path for LSTM weights

    ##### Queue Configuration #####

    REDIS_URL: Optional[str] = os.getenv("REDIS_URL", None) # optional Redis URL for shared queue
    USE_REDIS: bool = REDIS_URL is not None # True when Redis-backed queue is configured

    ##### Logging #####

    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO") # root/service log level name
    LOG_FILE: Optional[str] = os.getenv("LOG_FILE", None) # optional log file path

    ##### Server Configuration #####

    HOST: str = os.getenv("HOST", "0.0.0.0") # Flask bind host
    PORT: int = int(os.getenv("PORT", "8000")) # Flask bind port

    ##### Model Architecture (matching TensorFlow version) #####

    LSTM_HIDDEN_SIZE_1: int = 60 # first LSTM hidden size
    LSTM_HIDDEN_SIZE_2: int = 120 # second LSTM hidden size
    DROPOUT_RATE: float = 0.3 # dropout between LSTM / dense stages
    DENSE_SIZE: int = 20 # penultimate dense layer width
    SEQUENCE_LENGTH: int = int(os.getenv("SEQUENCE_LENGTH", "7")) # lookback window length
    MAX_PREDICTIONS: int = 3 # hard cap on future steps per request

    ##### Training Configuration #####

    TRAINING_EPOCHS: int = int(os.getenv("TRAINING_EPOCHS", "80")) # epochs per per-step train
    TRAINING_BATCH_SIZE: int = int(os.getenv("TRAINING_BATCH_SIZE", "8")) # Adam training batch size


    ########## VALIDATE ##########

    @classmethod
    def validate(cls): # function to ensure required env and worker counts are sane

        if not cls.PREDICTION_SERVICE_KEY: # require interim shared secret for API auth
            raise ValueError("PREDICTION_SERVICE_KEY must be set in environment variables") # fail fast when missing
        if cls.NUM_GPU_WORKERS < 1: # need at least one GPU worker slot
            raise ValueError("NUM_GPU_WORKERS must be at least 1") # reject invalid worker count
        if cls.NUM_CPU_WORKERS < 1: # need at least one CPU worker slot
            raise ValueError("NUM_CPU_WORKERS must be at least 1") # reject invalid worker count


##### global config instance #####

config = Config() # shared Config singleton imported by the service
