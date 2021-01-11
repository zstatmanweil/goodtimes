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
        sa.Column('id', sa.Integer, primary_key=True, index=True),
        sa.Column('first_name', sa.String(100)),
        sa.Column('last_name', sa.String(100)),
        sa.Column('full_name', sa.String(150)),
        sa.Column('email', sa.String(100)),
        sa.Column('picture', sa.String(150)),
        sa.Column('created', sa.DateTime)
    )

    id: int = field(init=False)
    first_name: str
    last_name: str
    full_name: str
    email: str
    picture: str
    created: datetime

