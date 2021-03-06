from dataclasses import dataclass
from dataclasses import field
from datetime import date
from typing import Optional

from dataclasses_json import dataclass_json, config
from marshmallow import fields
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
        sa.Column('source_id', sa.String(50)),
        sa.Column('title', sa.String(200)),
        sa.Column('poster_url', sa.String(100)),
        sa.Column('release_date', sa.Date)
    )

    id: int = field(init=False)
    source: str
    source_id: str
    title: str
    poster_url: Optional[str]
    release_date: Optional[date] = field(
        metadata=config(
            encoder=date.isoformat,
            decoder=lambda x: date.fromisoformat(str(x)) if x else date(1900, 1, 1),
            mm_field=fields.Date(format='iso')
        )
    )
