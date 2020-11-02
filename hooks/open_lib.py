from typing import List, Dict

import requests

from models.books import Book, CoverSize, IdType


class OpenLibrary:
    def __init__(self):
        self.open_library_search_base_uri = 'http://openlibrary.org/search.json'
        self.open_library_cover_uri = 'http://covers.openlibrary.org/b'

    def get_books_by_title(self, title: str, cover_image_size: CoverSize) -> List[Book]:
        reformatted_title = title.replace(' ', '+')

        payload = {'title': reformatted_title}

        response = requests.get(self.open_library_search_base_uri, params=payload)

        response.raise_for_status()
        response_body = response.json()

        docs = response_body.get('docs')
        books = [self.book_from_open_lib_result(result=doc, image_size=cover_image_size) for doc in docs]
        return books

    def get_cover_by_id(self, cover_id: int, id_type: IdType, size: CoverSize) -> str:
        return f'{self.open_library_cover_uri}/{id_type.value}/{cover_id}-{size.value}.jpg'

    def book_from_open_lib_result(self, result: Dict, image_size: CoverSize) -> Book:
        clean_result = {}

        cover_id = result.get('cover_i', None)
        title = result.get('title', None)
        author_name = result.get('author_name', [])
        publish_year = result.get('publish_year', [])

        clean_result['cover_id'] = cover_id
        #TODO: if cover_id is Null, get cover url with other id
        clean_result['cover_url'] = self.get_cover_by_id(cover_id=cover_id, id_type=IdType.COVER_ID, size=image_size) if cover_id else None
        clean_result['title'] = title
        clean_result['author_name'] = author_name.pop(0) if author_name else None
        clean_result['publish_year'] = publish_year.pop(0) if publish_year else None

        return Book.from_dict(clean_result)
