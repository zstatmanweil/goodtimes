from typing import List, Dict

import requests

from models.books import Book
from secrets import GOOGLE_BOOKS_API_KEY


class GoogleBooks:
    def __init__(self):
        self.base_uri = 'https://www.googleapis.com/books/v1/volumes'
        self.api_key = GOOGLE_BOOKS_API_KEY

    def get_books_by_title(self, title: str) -> List[Book]:
        payload = {'q': f'intitle:"{title}"',
                   'key': self.api_key,
                   'maxResults': 40}

        response = requests.get(self.base_uri, params=payload)

        response.raise_for_status()
        response_body = response.json()

        items = response_body.get('items')
        books = [self.book_from_google_books_result(result=item) for item in items]
        return books

    def book_from_google_books_result(self, result: Dict) -> Book:
        clean_result = {}

        source_id = result.get('id', None)

        info = result.get('volumeInfo')
        title = info.get('title', None)
        author_name = info.get('authors', [])
        publish_year = info.get('publishedDate', None)
        image_links = info.get('imageLinks', None)

        clean_result['source_id'] = source_id
        clean_result['source'] = 'google books api'
        clean_result['title'] = title.title()
        clean_result['author_name'] = author_name.pop(0).title() if author_name else None
        clean_result['publish_year'] = int(publish_year.split('-')[0].replace('*', '')) if publish_year else None
        clean_result['cover_url'] = image_links.get('thumbnail', None) if image_links else None

        return Book.from_dict(clean_result)
