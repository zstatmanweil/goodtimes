from dataclasses import dataclass
from dataclasses import field
from typing import Optional

from dataclasses_json import dataclass_json
from enum import Enum
import sqlalchemy as sa
from sqlalchemy.orm import registry

mapper_registry = registry()


@mapper_registry.mapped
@dataclass_json
@dataclass
class Book:
    __table__ = sa.Table(
        "book",
        mapper_registry.metadata,
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source', sa.String(50)),
        sa.Column('source_id', sa.String(50)),
        sa.Column('title', sa.String(200)),
        sa.Column('author_name', sa.String(100)),
        sa.Column('cover_url', sa.String(250)),
        sa.Column('publish_year', sa.Integer)
    )

    # TODO: make author_name a list
    id: int = field(init=False)
    source: str
    source_id: str
    title: str
    author_name: Optional[str]
    publish_year: Optional[int]
    cover_url: Optional[str]


class CoverSize(Enum):
    SMALL = 'S'
    MEDIUM = 'M'
    LARGE = 'L'


class IdType(Enum):
    ISBN = 'isbn'
    OCLC = 'oclc'
    LCCN = 'lccn'
    OPEN_LIBRARY_ID = "olid"
    COVER_ID = 'id'
    GOODREADS = 'goodreads'
    LIBRARYTHINGS = 'librarythings'
