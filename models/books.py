from dataclasses import dataclass
from dataclasses_json import dataclass_json
from typing import Dict


@dataclass_json
@dataclass
class Book:
    cover_id: int
    title: str
    author_name: str
    publish_year: int


def from_open_lib_result(result: Dict) -> Dict:
    clean_result = {}

    clean_result['cover_id'] = result.get('cover_i')
    clean_result['title'] = result.get('title')
    clean_result['author_name'] = result.get('author_name').pop(0)
    clean_result['publish_year'] = result.get('publish_year').pop(0)

    return clean_result

