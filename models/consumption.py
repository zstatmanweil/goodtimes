from dataclasses import dataclass
from dataclasses import field
from datetime import datetime

from dataclasses_json import dataclass_json
from enum import Enum
import sqlalchemy as sa
from sqlalchemy.orm import registry

from models.user import User


mapper_registry = registry()


@mapper_registry.mapped
@dataclass_json
@dataclass
class Consumption:
    __table__ = sa.Table(
        'consumption',
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey(User.id)),
        sa.Column('media_type', sa.String(50)),
        sa.Column('media_id', sa.Integer),
        sa.Column('source_id', sa.String(50), index=True),
        sa.Column('status', sa.String(50)),
        sa.Column('created', sa.DateTime)
    )

    id: int = field(init=False)
    user_id: int
    media_type: str
    media_id: int
    source_id: str
    status: str
    created: datetime


class ConsumptionStatus(Enum):
    WANT_TO_CONSUME = "want to consume"
    CONSUMING = "consuming"
    FINISHED = "finished"
    ABANDONED = "abandoned"
