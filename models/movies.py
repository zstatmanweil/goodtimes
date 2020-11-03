from dataclasses import dataclass

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class Movie:
    title: str
    release_date: str
    poster_url: str
