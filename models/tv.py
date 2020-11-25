from dataclasses import dataclass
from dataclasses import field
from datetime import date
from typing import List, Optional

from dataclasses_json import dataclass_json, config
from marshmallow import fields
import sqlalchemy as sa
from sqlalchemy.orm import registry

mapper_registry = registry()


@mapper_registry.mapped
@dataclass_json
@dataclass
class TV:
    __table__ = sa.Table(
        'tv',
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source', sa.String(50)),
        sa.Column('source_id', sa.String(50)),
        sa.Column('title', sa.String(200)),
        sa.Column('networks', sa.ARRAY(sa.String(50))),
        sa.Column('poster_url', sa.String(100)),
        sa.Column('first_air_date', sa.Date)
    )

    id: int = field(init=False)
    source_id: str
    source: str
    title: str
    networks: List[str]
    poster_url: Optional[str]
    first_air_date: Optional[date] = field(
        metadata=config(
            encoder=date.isoformat,
            decoder=lambda x: date.fromisoformat(str(x)) if x is not None else None,
            mm_field=fields.Date(format='iso')
        )
    )

