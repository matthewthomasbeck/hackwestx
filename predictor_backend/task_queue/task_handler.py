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

import logging # import logging for task processing diagnostics
from typing import Any, Dict, Optional # import typing helpers

##### import third-party libraries #####

import numpy as np # import numpy for fitted/future prediction arrays
import requests # import requests for callback HTTP POST
import torch # import torch for inference tensors

##### import local modules #####

import config # import SEQUENCE_LENGTH / TRAINING_* settings
from models.model_loader import ModelManager # import device/model access
from models.trainer import create_trained_model, prepare_data_with_step # import per-step train helpers
from task_queue.queue_manager import Task # import Task dataclass
from utils.date_utils import generate_future_dates # import future x-axis labels
from utils.json_formatter import (
    extract_series_from_json, # import series list extractor
    format_predictions_for_json, # import prediction series formatter
    inject_predictions_into_json, # import result JSON assembler
    validate_json_structure, # import inbound schema check
)
from utils.postprocessing import (
    generate_fitted_predictions, # import historical fitted-pass helper
    process_model_outputs, # import denormalize helper
)
from utils.preprocessing import (
    create_sequences, # import sequence builder
    extract_time_series_data, # import x/y extract+sort
    normalize_data, # import MinMaxScaler fit/transform
    prepare_prediction_input, # import last-window reshape
)





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### TASK HANDLER #####################
##################################################


########## TASK HANDLER ##########

class TaskHandler: # class to run LSTM prediction jobs and POST callback results

    ########## INIT ##########

    def __init__(self, model_manager: ModelManager): # function to bind model manager and cache model/device

        self.model_manager = model_manager # store model manager handle
        self.model = model_manager.get_model() # cache current model (may be None until load)
        self.device = model_manager.get_device() # cache inference device
        logger.info("Task handler initialized") # log init


    ########## PROCESS TASK ##########

    def process_task(self, task: Task) -> Optional[Dict[str, Any]]: # function to run LSTM training/inference per series and inject predictions into JSON

        try:
            logger.info(f"Processing task {task.task_id}") # start task

            validate_json_structure(task.json_data) # reject malformed inbound JSON

            num_predictions = min(
                task.json_data.get("numPredictions", 3),
                3
            ) # cap future steps at 3

            series_list = extract_series_from_json(task.json_data) # pull timeSeries entries
            date_format = task.json_data["xAxis"]["format"] # x-axis date format for future labels

            MIN_DATA_POINTS = 8 # sequence_length (7) + 1 minimum
            predictions_dict = {} # map series name → prediction payload
            skipped_series = [] # names skipped for insufficient data or errors

            for series in series_list: # process each series independently
                series_name = series["name"] # series label
                series_data = series["data"] # [{x, y}, ...] points

                try:
                    logger.debug(f"Processing series: {series_name}") # per-series start

                    times, values = extract_time_series_data(series_data) # sorted x/y arrays

                    if len(values) < MIN_DATA_POINTS: # not enough history to train
                        logger.warning(
                            f"Skipping series '{series_name}': insufficient data points "
                            f"({len(values)} < {MIN_DATA_POINTS} required)"
                        )
                        skipped_series.append(series_name)
                        continue

                    normalized_values, scaler = normalize_data(values) # fit MinMaxScaler

                    sequence_length = config.config.SEQUENCE_LENGTH # window size from config
                    future_steps = list(range(1, num_predictions + 1)) # e.g. [1, 2, 3]

                    trained_models = {} # step → trained model
                    future_predictions_list = [] # normalized future preds in step order

                    logger.debug(f"Training {len(future_steps)} models for series '{series_name}'...")

                    for step in future_steps: # train one model per horizon
                        trainX, trainY, lastSequence = prepare_data_with_step(
                            normalized_values,
                            step=step,
                            sequence_length=sequence_length
                        ) # target shifted by step

                        model = create_trained_model(
                            trainX=trainX,
                            trainY=trainY,
                            device=self.device,
                            epochs=config.config.TRAINING_EPOCHS,
                            batch_size=config.config.TRAINING_BATCH_SIZE,
                            sequence_length=sequence_length
                        ) # train LSTM for this step
                        trained_models[step] = model

                        last_seq_tensor = torch.FloatTensor(lastSequence).unsqueeze(0).unsqueeze(-1).to(self.device)
                        model.eval()
                        with torch.no_grad():
                            pred = model(last_seq_tensor)
                            future_predictions_list.append(pred.cpu().item())

                    max_step = max(future_steps) # use farthest-horizon model for fitted pass
                    fitted_model = trained_models[max_step]

                    trainX_fitted, trainY_fitted, _ = prepare_data_with_step(
                        normalized_values,
                        step=max_step,
                        sequence_length=sequence_length
                    ) # training windows for fitted curve

                    trainX_tensor = torch.FloatTensor(trainX_fitted).to(self.device)
                    fitted_model.eval()
                    with torch.no_grad():
                        fitted_preds_normalized_tensor = fitted_model(trainX_tensor)
                        fitted_preds_normalized = fitted_preds_normalized_tensor.cpu().numpy().flatten()

                    first_seq_actual = normalized_values[:sequence_length] # seed fitted curve with first window
                    fitted_preds_normalized_full = np.concatenate([
                        first_seq_actual,
                        fitted_preds_normalized
                    ])

                    if len(fitted_preds_normalized_full) > len(values): # trim to history length
                        fitted_preds_normalized_full = fitted_preds_normalized_full[:len(values)]
                    elif len(fitted_preds_normalized_full) < len(values): # pad with last pred if short
                        missing = len(values) - len(fitted_preds_normalized_full)
                        last_pred = fitted_preds_normalized_full[-1] if len(fitted_preds_normalized_full) > 0 else normalized_values[-1]
                        fitted_preds_normalized_full = np.append(
                            fitted_preds_normalized_full,
                            [last_pred] * missing
                        )

                    fitted_predictions = scaler.inverse_transform(
                        fitted_preds_normalized_full.reshape(-1, 1)
                    ).flatten() # denormalize fitted

                    future_predictions = scaler.inverse_transform(
                        np.array(future_predictions_list).reshape(-1, 1)
                    ).flatten() # denormalize future

                    last_date = times[-1] # last historical x
                    future_dates = generate_future_dates(last_date, date_format, num_predictions)

                    prediction_dict = format_predictions_for_json(
                        series_name=series_name,
                        times=times,
                        fitted_predictions=fitted_predictions.tolist(),
                        future_times=future_dates,
                        future_predictions=future_predictions.tolist()
                    )
                    predictions_dict[series_name] = prediction_dict
                    logger.debug(f"Successfully processed series: {series_name}")

                except Exception as e:
                    logger.warning(
                        f"Error processing series '{series_name}': {e}. Skipping this series."
                    )
                    skipped_series.append(series_name)
                    continue

            if skipped_series:
                logger.warning(
                    f"Skipped {len(skipped_series)} series due to insufficient data or errors: "
                    f"{', '.join(skipped_series)}"
                )

            predictions_list = [] # preserve timeSeries order
            for series in series_list:
                series_name = series["name"]
                if series_name in predictions_dict:
                    predictions_list.append(predictions_dict[series_name])
                else:
                    logger.debug(f"Including skipped series '{series_name}' with original data")
                    predictions_list.append({
                        "name": series_name,
                        "data": series["data"] # original data, no future predictions
                    })

            if not predictions_list:
                logger.error(f"No series could be processed for task {task.task_id}")
                return None

            result_json = inject_predictions_into_json(
                task.json_data,
                predictions_list,
                num_predictions
            )

            logger.info(f"Task {task.task_id} completed successfully")
            return result_json

        except Exception as e:
            logger.error(f"Error processing task {task.task_id}: {e}", exc_info=True)
            return None


    ########## SEND CALLBACK ##########

    def send_callback(
        self,
        callback_url: str,
        result_json: Dict[str, Any],
        timeout: int = 30,
    ) -> bool: # function to POST completed prediction JSON to callback_url

        try:
            response = requests.post(
                callback_url,
                json=result_json,
                timeout=timeout,
                headers={"Content-Type": "application/json"}
            ) # POST result payload
            response.raise_for_status() # raise on non-2xx
            logger.info(f"Callback sent successfully to {callback_url}")
            return True
        except Exception as e:
            logger.error(f"Failed to send callback to {callback_url}: {e}")
            return False
