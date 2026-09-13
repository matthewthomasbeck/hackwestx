##################################################################################
# Copyright (c) 2026 Matthew Thomas Beck                                         #
#                                                                                #
# Licensed under the Creative Commons Attribution-NonCommercial 4.0              #
# International (CC BY-NC 4.0). Personal and educational use is permitted.       #
# Commercial use by companies or for-profit entities is prohibited.              #
##################################################################################





############################################################
############### TASK QUEUE PACKAGE #######################
############################################################


# In-memory prediction task queue and LSTM task handler live in this package.

##### re-export public queue API #####

from .queue_manager import QueueManager, Task # import queue manager and Task dataclass
from .task_handler import TaskHandler # import prediction task processor

__all__ = ["QueueManager", "Task", "TaskHandler"] # public symbols for `from task_queue import ...`
