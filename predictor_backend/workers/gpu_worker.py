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

import logging # import logging for worker task diagnostics
import threading # import threading for shutdown_event and stats lock
from typing import Optional # import Optional for TaskHandler handle

##### import third-party libraries #####

import torch # import torch for CUDA cache cleanup

##### import local modules #####

from models.model_loader import ModelManager # import model/device manager for TaskHandler
from task_queue import QueueManager # import queue for dequeue/mark_* 
from task_queue.task_handler import TaskHandler # import LSTM process + callback handler





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### GPU WORKER #######################
##################################################


########## GPU WORKER ##########

class GPUWorker: # class to dequeue tasks, run LSTM via TaskHandler, and send callbacks

    ########## INIT ##########

    def __init__(
        self,
        worker_id: str,
        queue_manager: QueueManager,
        model_manager: ModelManager,
        shutdown_event: threading.Event,
    ): # function to store queue/model handles and init per-worker stats

        self.worker_id = worker_id # unique worker name
        self.queue_manager = queue_manager # shared prediction queue
        self.model_manager = model_manager # shared model/device manager
        self.shutdown_event = shutdown_event # cooperative stop signal
        self.task_handler: Optional[TaskHandler] = None # created in run()
        self._lock = threading.Lock() # protect stats dict
        self._stats = {
            "tasks_processed": 0,
            "tasks_failed": 0,
            "is_running": False
        } # zeroed counters
        logger.info(f"GPU worker {worker_id} initialized") # log init


    ########## RUN ##########

    def run(self) -> None: # function to dequeue tasks, process via TaskHandler, send callbacks

        logger.info(f"GPU worker {self.worker_id} started") # log start

        self.task_handler = TaskHandler(self.model_manager) # bind LSTM handler for this thread

        with self._lock:
            self._stats["is_running"] = True # mark running

        try:
            while not self.shutdown_event.is_set(): # dequeue until stop
                task = self.queue_manager.dequeue(timeout=1.0) # wait briefly for work

                if task is None:
                    continue # timeout / empty

                try:
                    logger.debug(f"Worker {self.worker_id} processing task {task.task_id}")
                    result = self.task_handler.process_task(task) # train/infer/inject

                    if result is not None:
                        if task.callback_url:
                            logger.info(f"Sending callback for task {task.task_id} to {task.callback_url}")
                            callback_success = self.task_handler.send_callback(task.callback_url, result)
                            if callback_success:
                                logger.info(f"Callback sent successfully for task {task.task_id}")
                            else:
                                logger.warning(f"Callback failed for task {task.task_id}")
                        else:
                            logger.warning(
                                f"Task {task.task_id} completed but no callback URL provided. "
                                f"Results will not be sent back. Consider providing a callback_url parameter."
                            )

                        self.queue_manager.mark_completed(task.task_id) # drop from active

                        with self._lock:
                            self._stats["tasks_processed"] += 1

                        logger.info(
                            f"Worker {self.worker_id} completed task {task.task_id}"
                        )
                    else:
                        self.queue_manager.mark_failed(task.task_id) # permanent fail

                        with self._lock:
                            self._stats["tasks_failed"] += 1

                        logger.error(
                            f"Worker {self.worker_id} failed to process task {task.task_id}"
                        )

                except Exception as e:
                    logger.error(
                        f"Worker {self.worker_id} error processing task {task.task_id}: {e}",
                        exc_info=True
                    )
                    self.queue_manager.mark_failed(task.task_id)

                    with self._lock:
                        self._stats["tasks_failed"] += 1

        except Exception as e:
            logger.error(f"GPU worker {self.worker_id} crashed: {e}", exc_info=True)

        finally:
            with self._lock:
                self._stats["is_running"] = False # clear running
            logger.info(f"GPU worker {self.worker_id} stopped")


    ########## CLEANUP ##########

    def cleanup(self) -> None: # function to clear CUDA cache and drop TaskHandler on shutdown

        logger.debug(f"Cleaning up GPU worker {self.worker_id}")

        if torch.cuda.is_available(): # free GPU memory if present
            torch.cuda.empty_cache()

        self.task_handler = None # drop handler reference


    ########## GET STATS ##########

    def get_stats(self) -> dict: # function to return this worker's processed/failed/running counters

        with self._lock:
            return {
                "worker_id": self.worker_id,
                **self._stats
            } # snapshot under lock
