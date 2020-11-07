from dataclasses import dataclass
from datetime import date
from typing import List, Optional

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class TV:
    source_id: int
    source: str
    title: str
    networks: List[str]
    poster_url: Optional[str] = None
    first_air_date: Optional[date] = None
