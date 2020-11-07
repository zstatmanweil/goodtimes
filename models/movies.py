from dataclasses import dataclass
from datetime import date
from typing import Optional

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class Movie:
    source_id: int
    source: str
    title: str
    poster_url: Optional[str] = None
    release_date: Optional[date] = None
