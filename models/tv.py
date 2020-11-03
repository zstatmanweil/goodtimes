from dataclasses import dataclass

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class TV:
    tmdb_id: int
    title: str
    first_air_date: str
    poster_url: str
