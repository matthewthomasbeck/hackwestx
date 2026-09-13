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

import logging # import logging for enqueue/dequeue diagnostics
import queue # import queue for thread-safe task buffer
import threading # import threading for locks and shutdown event
import uuid # import uuid for task_id generation
from dataclasses import dataclass # import dataclass for Task fields
from datetime import datetime # import datetime for task timestamps
from typing import Any, Dict, Optional # import typing helpers





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER ##########

logger = logging.getLogger(__name__) # create module logger





##################################################
############### TASK DATACLASS ###################
##################################################


########## TASK ##########

@dataclass
class Task: # dataclass representing one queued prediction job

    task_id: str # unique task identifier
    json_data: Dict[str, Any] # inbound timeSeries JSON payload
    callback_url: Optional[str] # optional POST URL for completed predictions
    timestamp: datetime # enqueue time
    retry_count: int = 0 # current retry attempts
    max_retries: int = 3 # max retries before permanent failure





##################################################
############### QUEUE MANAGER ####################
##################################################


########## QUEUE MANAGER ##########

class QueueManager: # class for thread-safe prediction task queue with stats and shutdown

    ########## INIT ##########

    def __init__(self, maxsize: int = 1000): # function to create bounded queue, active-task map, and stats

        self._queue: queue.Queue = queue.Queue(maxsize=maxsize) # bounded thread-safe queue
        self._active_tasks: Dict[str, Task] = {} # in-flight / enqueued task map
        self._lock = threading.Lock() # protect stats and active_tasks
        self._shutdown_event = threading.Event() # signals accept-no-more-work
        self._stats = {
            "total_enqueued": 0,
            "total_processed": 0,
            "total_failed": 0,
            "current_queue_size": 0
        } # zeroed counters
        logger.info("Queue manager initialized") # log init


    ########## ENQUEUE ##########

    def enqueue(
        self,
        json_data: Dict[str, Any],
        callback_url: Optional[str] = None,
    ) -> str: # function to add a Task to the queue and return its task_id

        if self._shutdown_event.is_set(): # refuse work after shutdown
            raise RuntimeError("Queue manager is shutdown") # hard fail

        task_id = str(uuid.uuid4()) # generate unique id
        task = Task(
            task_id=task_id,
            json_data=json_data,
            callback_url=callback_url,
            timestamp=datetime.now()
        ) # build Task dataclass

        try:
            self._queue.put(task, timeout=5) # block briefly if near capacity
            with self._lock: # update bookkeeping
                self._active_tasks[task_id] = task # track active
                self._stats["total_enqueued"] += 1 # bump enqueue count
                self._stats["current_queue_size"] = self._queue.qsize() # refresh size
            logger.info(f"Task {task_id} enqueued. Queue size: {self._queue.qsize()}") # log
            return task_id # return id to caller
        except queue.Full: # timed out waiting for space
            logger.error("Queue is full, cannot enqueue task") # log
            raise RuntimeError("Queue is full") # surface to API


    ########## DEQUEUE ##########

    def dequeue(self, timeout: Optional[float] = None) -> Optional[Task]: # function to pop next Task or None on timeout

        try:
            task = self._queue.get(timeout=timeout) # wait for next task
            with self._lock: # update size stat
                self._stats["current_queue_size"] = self._queue.qsize() # refresh
            return task # next work item
        except queue.Empty: # timeout / empty
            return None # no work available


    ########## MARK COMPLETED ##########

    def mark_completed(self, task_id: str) -> None: # function to remove active task and increment processed count

        with self._lock: # protect maps/stats
            if task_id in self._active_tasks: # known task
                del self._active_tasks[task_id] # drop from active
                self._stats["total_processed"] += 1 # bump processed
            self._stats["current_queue_size"] = self._queue.qsize() # refresh size


    ########## MARK FAILED ##########

    def mark_failed(self, task_id: str) -> None: # function to retry requeue or count permanent failure

        with self._lock: # protect maps/stats
            if task_id in self._active_tasks: # known task
                task = self._active_tasks[task_id] # fetch task
                task.retry_count += 1 # bump retry
                if task.retry_count < task.max_retries: # still retries left
                    try:
                        self._queue.put(task, timeout=1) # requeue for retry
                        logger.info(f"Task {task_id} requeued for retry ({task.retry_count}/{task.max_retries})") # log
                    except queue.Full: # cannot requeue
                        logger.error(f"Could not requeue task {task_id}, queue is full") # log
                        del self._active_tasks[task_id] # drop
                        self._stats["total_failed"] += 1 # count failure
                else: # max retries reached
                    del self._active_tasks[task_id] # drop permanently
                    self._stats["total_failed"] += 1 # count failure
                    logger.error(f"Task {task_id} failed after {task.max_retries} retries") # log
            self._stats["current_queue_size"] = self._queue.qsize() # refresh size


    ########## GET STATS ##########

    def get_stats(self) -> Dict[str, Any]: # function to return enqueue/processed/failed/queue size snapshot

        with self._lock: # consistent snapshot
            return {
                **self._stats,
                "active_tasks": len(self._active_tasks),
                "queue_size": self._queue.qsize()
            } # counters + live sizes


    ########## SHUTDOWN ##########

    def shutdown(self) -> None: # function to stop accepting work and drain/clear remaining tasks

        logger.info("Shutting down queue manager...") # log start
        self._shutdown_event.set() # stop accepting new work

        ##### wait for queue to empty (with timeout) #####

        timeout = 30 # seconds to wait for natural drain
        start_time = datetime.now() # drain start
        while not self._queue.empty(): # wait while items remain
            if (datetime.now() - start_time).total_seconds() > timeout: # timed out
                logger.warning("Queue did not empty within timeout") # warn
                break # force clear next

        ##### clear remaining tasks #####

        while not self._queue.empty(): # drop leftovers
            try:
                self._queue.get_nowait() # non-blocking pop
            except queue.Empty: # race with empty
                break # done

        with self._lock: # clear active map
            self._active_tasks.clear() # drop all tracked tasks

        logger.info("Queue manager shutdown complete") # log done


    ########## IS SHUTDOWN ##########

    def is_shutdown(self) -> bool: # function to report whether queue manager has been shut down

        return self._shutdown_event.is_set() # True after shutdown()
