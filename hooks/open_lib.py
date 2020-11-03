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

    def get_cover_by_id(self, id: int, id_type: IdType, size: CoverSize) -> str:
        return f'{self.open_library_cover_uri}/{id_type.value}/{id}-{size.value}.jpg'

    def book_from_open_lib_result(self, result: Dict, image_size: CoverSize) -> Book:
        clean_result = {}

        cover_id = result.get('cover_i', None)
        isbns = result.get('isbn', [])
        title = result.get('title', None)
        author_names = result.get('author_name', [])
        publish_years = result.get('publish_year', [])

        clean_result['cover_id'] = cover_id
        clean_result['isbns'] = isbns
        clean_result['title'] = title.title()
        clean_result['author_name'] = author_names.pop(0).title() if author_names else None
        clean_result['publish_year'] = publish_years.pop(0) if publish_years else None

        if cover_id:
            clean_result['cover_url'] = self.get_cover_by_id(id=cover_id, id_type=IdType.COVER_ID, size=image_size)
        elif isbns:
            clean_result['cover_url'] = self.get_cover_by_id(id=isbns[0], id_type=IdType.ISBN, size=image_size)
        else:
            clean_result['cover_url'] = None

        return Book.from_dict(clean_result)
