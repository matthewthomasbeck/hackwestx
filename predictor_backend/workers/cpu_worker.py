############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for worker lifecycle messages
import threading # import threading for shutdown_event and stats lock
from typing import Optional # import Optional for typing symmetry with GPU worker

##### import local modules #####

from task_queue import QueueManager # import queue manager (reserved for future CPU preprocess work)





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### CPU WORKER #######################
##################################################


########## CPU WORKER ##########

class CPUWorker: # class for CPU-side helper worker (preprocess/postprocess expansion)

    ########## INIT ##########

    def __init__(
        self,
        worker_id: str,
        queue_manager: QueueManager,
        shutdown_event: threading.Event,
    ): # function to store worker id, queue handle, and shared shutdown event

        self.worker_id = worker_id # unique worker name
        self.queue_manager = queue_manager # shared queue (future preprocess use)
        self.shutdown_event = shutdown_event # cooperative stop signal
        self._lock = threading.Lock() # protect stats dict
        self._stats = {
            "tasks_processed": 0,
            "tasks_failed": 0,
            "is_running": False
        } # zeroed counters
        logger.info(f"CPU worker {worker_id} initialized") # log init


    ########## RUN ##########

    def run(self) -> None: # function to idle-loop until shutdown (placeholder for CPU preprocess work)

        logger.info(f"CPU worker {self.worker_id} started") # log start

        with self._lock:
            self._stats["is_running"] = True # mark running

        try:
            while not self.shutdown_event.is_set(): # idle until stop
                if self.shutdown_event.wait(timeout=1.0): # wake on shutdown or timeout
                    break

        except Exception as e:
            logger.error(f"CPU worker {self.worker_id} crashed: {e}", exc_info=True)

        finally:
            with self._lock:
                self._stats["is_running"] = False # clear running
            logger.info(f"CPU worker {self.worker_id} stopped")


    ########## CLEANUP ##########

    def cleanup(self) -> None: # function to release CPU worker resources on shutdown

        logger.debug(f"Cleaning up CPU worker {self.worker_id}") # no-op cleanup for CPU workers


    ########## GET STATS ##########

    def get_stats(self) -> dict: # function to return this worker's processed/failed/running counters

        with self._lock:
            return {
                "worker_id": self.worker_id,
                **self._stats
            } # snapshot under lock
