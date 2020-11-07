from dataclasses import dataclass
from typing import Optional, List

from dataclasses_json import dataclass_json

from enum import Enum


@dataclass_json
@dataclass
class Book:
    source_id: str
    source: str
    title: str
    author_name: str
    publish_year: int
    isbns: List
    cover_id: Optional[int] = None
    cover_url: Optional[str] = None


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


