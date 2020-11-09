from enum import Enum


class ConsumptionStatus(Enum):
    WANT_TO_CONSUME = "want to consume"
    CONSUMING = "consuming"
    FINISHED = "finished"
    ABANDONED = "abandoned"
