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

import logging # import logging for pool lifecycle messages
import signal # import signal for SIGINT/SIGTERM → shutdown
import threading # import threading for worker threads and shutdown event
from typing import List, Optional # import typing helpers

##### import local modules #####

import config # import NUM_GPU_WORKERS / NUM_CPU_WORKERS defaults
from models.model_loader import ModelManager # import shared model manager for GPU workers
from task_queue import QueueManager # import shared prediction queue
from workers.cpu_worker import CPUWorker # import CPU helper worker class
from workers.gpu_worker import GPUWorker # import GPU inference worker class





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger("prediction_service") # create module logger





##################################################
############### WORKER MANAGER ###################
##################################################


########## WORKER MANAGER ##########

class WorkerManager: # class to start/stop GPU+CPU worker thread pools with graceful shutdown

    ########## INIT ##########

    def __init__(
        self,
        queue_manager: QueueManager,
        model_manager: ModelManager,
        num_gpu_workers: Optional[int] = None,
        num_cpu_workers: Optional[int] = None,
    ): # function to bind managers, worker counts, and register signal handlers

        self.queue_manager = queue_manager # shared prediction queue
        self.model_manager = model_manager # shared model/device manager
        self.num_gpu_workers = num_gpu_workers or config.config.NUM_GPU_WORKERS # GPU pool size
        self.num_cpu_workers = num_cpu_workers or config.config.NUM_CPU_WORKERS # CPU pool size

        self.gpu_workers: List[GPUWorker] = [] # GPU worker instances
        self.cpu_workers: List[CPUWorker] = [] # CPU worker instances
        self.worker_threads: List[threading.Thread] = [] # all worker threads

        self._shutdown_event = threading.Event() # cooperative stop for all workers
        self._lock = threading.Lock() # protect get_worker_stats snapshot

        signal.signal(signal.SIGINT, self._signal_handler) # Ctrl-C → graceful shutdown
        signal.signal(signal.SIGTERM, self._signal_handler) # terminate → graceful shutdown

        logger.info(
            f"Worker manager initialized: {self.num_gpu_workers} GPU workers, "
            f"{self.num_cpu_workers} CPU workers"
        )


    ########## SIGNAL HANDLER ##########

    def _signal_handler(self, signum, frame): # function to map OS signals into graceful worker shutdown

        logger.info(f"Received signal {signum}, initiating graceful shutdown...")
        self.shutdown() # stop workers + queue


    ########## START ##########

    def start(self) -> None: # function to spawn GPU and CPU worker threads

        logger.info("Starting workers...")

        for i in range(self.num_gpu_workers): # spawn GPU inference workers
            worker = GPUWorker(
                worker_id=f"gpu-{i}",
                queue_manager=self.queue_manager,
                model_manager=self.model_manager,
                shutdown_event=self._shutdown_event
            )
            self.gpu_workers.append(worker)

            thread = threading.Thread(
                target=worker.run,
                name=f"GPUWorker-{i}",
                daemon=False # joinable on shutdown
            )
            thread.start()
            self.worker_threads.append(thread)
            logger.info(f"Started GPU worker {i}")

        for i in range(self.num_cpu_workers): # spawn CPU helper workers
            worker = CPUWorker(
                worker_id=f"cpu-{i}",
                queue_manager=self.queue_manager,
                shutdown_event=self._shutdown_event
            )
            self.cpu_workers.append(worker)

            thread = threading.Thread(
                target=worker.run,
                name=f"CPUWorker-{i}",
                daemon=False # joinable on shutdown
            )
            thread.start()
            self.worker_threads.append(thread)
            logger.info(f"Started CPU worker {i}")

        logger.info(f"All {len(self.worker_threads)} workers started")


    ########## SHUTDOWN ##########

    def shutdown(self, timeout: float = 30.0) -> None: # function to signal stop, drain queue, join threads, cleanup workers

        if self._shutdown_event.is_set(): # idempotent
            logger.warning("Shutdown already in progress")
            return

        logger.info("Shutting down workers...")
        self._shutdown_event.set() # wake idle workers

        self.queue_manager.shutdown() # refuse new enqueue / unblock dequeue

        for thread in self.worker_threads: # join each worker thread
            if thread.is_alive():
                logger.debug(f"Waiting for thread {thread.name} to finish...")
                thread.join(timeout=timeout / len(self.worker_threads) if self.worker_threads else timeout)
                if thread.is_alive():
                    logger.warning(f"Thread {thread.name} did not finish within timeout")

        for worker in self.gpu_workers: # CUDA cleanup etc.
            worker.cleanup()

        for worker in self.cpu_workers: # CPU cleanup (no-op)
            worker.cleanup()

        logger.info("All workers shutdown complete")


    ########## IS RUNNING ##########

    def is_running(self) -> bool: # function to report whether shutdown has not been signaled

        return not self._shutdown_event.is_set() # True until shutdown


    ########## GET WORKER STATS ##########

    def get_worker_stats(self) -> dict: # function to aggregate GPU/CPU worker counts and per-worker stats

        with self._lock:
            return {
                "gpu_workers": len(self.gpu_workers),
                "cpu_workers": len(self.cpu_workers),
                "active_threads": sum(1 for t in self.worker_threads if t.is_alive()),
                "gpu_worker_stats": [
                    w.get_stats() for w in self.gpu_workers
                ],
                "cpu_worker_stats": [
                    w.get_stats() for w in self.cpu_workers
                ]
            } # aggregate snapshot
