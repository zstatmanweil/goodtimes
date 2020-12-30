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
class Friend:
    __table__ = sa.Table(
        'friend',
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('requester_id', sa.Integer, sa.ForeignKey("user.id")),
        sa.Column('requested_id', sa.Integer, sa.ForeignKey("user.id")),
        sa.Column('status', sa.String(50)),
        sa.Column('created', sa.DateTime)
    )

    id: int = field(init=False)
    requester_id: int
    requested_id: int
    status: str
    created: datetime


class FriendStatus(Enum):
    REQUESTED = "requested"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    UNFRIEND = "unfriend"