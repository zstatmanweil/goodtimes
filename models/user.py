from dataclasses import dataclass
from dataclasses import field
from datetime import datetime

from dataclasses_json import dataclass_json
from enum import Enum
import sqlalchemy as sa
from sqlalchemy.orm import registry

mapper_registry = registry()


@mapper_registry.mapped
@dataclass_json
@dataclass
class User:
    __table__ = sa.Table(
        'user',
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('username', sa.String(100)),
        sa.Column('email', sa.String(100)),
        sa.Column('first_name', sa.String(100)),
        sa.Column('last_name', sa.String(100)),
        sa.Column('created', sa.DateTime)
    )

    id: int = field(init=False)
    username: str
    email: str
    first_name: str
    last_name: str
    created: datetime


class ConsumptionStatus(Enum):
    WANT_TO_CONSUME = "want to consume"
    CONSUMING = "consuming"
    FINISHED = "finished"
    ABANDONED = "abandoned"
