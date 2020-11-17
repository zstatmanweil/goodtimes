from typing import List, Dict

import requests

from models.books import Book
from secrets import GOOGLE_BOOKS_API_KEY


class GoogleBooks:
    def __init__(self):
        self.base_uri = 'https://www.googleapis.com/books/v1/volumes'
        self.api_key = GOOGLE_BOOKS_API_KEY

    def get_books_by_title(self, title: str) -> List[Book]:
        payload = {'q': f'intitle:{title}',
                   'key': self.api_key}

        response = requests.get(self.base_uri, params=payload)

        response.raise_for_status()
        response_body = response.json()

        items = response_body.get('items')
        books = [self.book_from_google_books_result(result=item) for item in items]
        return books

    def get_books_by_query(self, query: str) -> List[Book]:
        payload = {'q': query,
                   'key': self.api_key}

        response = requests.get(self.base_uri, params=payload)

        response.raise_for_status()
        response_body = response.json()

        items = response_body.get('items')
        books = [self.book_from_google_books_result(result=item) for item in items]
        return books

    @staticmethod
    def book_from_google_books_result(result: Dict) -> Book:
        clean_result = {}

        info = result.get('volumeInfo')
        publish_year = info.get('publishedDate', None)
        image_links = info.get('imageLinks', None)

        clean_result['source_id'] = result.get('id', None)
        clean_result['source'] = 'google books api'
        clean_result['title'] = info.get('title', None)
        clean_result['author_names'] = info.get('authors', [])
        clean_result['publish_year'] = int(publish_year.split('-')[0].replace('*', '')) if publish_year else None
        clean_result['cover_url'] = image_links.get('thumbnail', None) if image_links else None

        return Book.from_dict(clean_result)
