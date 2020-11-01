from models.books import from_open_lib_result
import requests


class OpenLibrary:
    def __init__(self):
        self.open_library_search_base_uri = 'http://openlibrary.org/search.json'

    def search_books_by_title(self, title: str):
        reformatted_title = title.replace(' ', '+')

        payload = {'title': reformatted_title}

        response = requests.get(self.open_library_search_base_uri, params=payload)

        response.raise_for_status()
        response_body = response.json()

        docs = response_body.get('docs')
        books = list(map(from_open_lib_result, docs))
        return books
