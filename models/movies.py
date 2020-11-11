from dataclasses import dataclass
from dataclasses import field
from datetime import date
from typing import Optional

from dataclasses_json import dataclass_json
import sqlalchemy as sa
from sqlalchemy.orm import registry

mapper_registry = registry()


@mapper_registry.mapped
@dataclass_json
@dataclass
class Movie:
    __table__ = sa.Table(
        'movie',
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source', sa.String(50)),
        sa.Column('source_id', sa.Integer),
        sa.Column('title', sa.String(200)),
        sa.Column('poster_url', sa.String(100)),
        sa.Column('release_date', sa.Date)
    )

    id: int = field(init=False)
    source: str
    source_id: int
    title: str
    poster_url: Optional[str] = None
    release_date: Optional[date] = None
