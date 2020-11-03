from typing import List, Dict

import requests

from models.movies import Movie


class TMDB:
    def __init__(self):
        self.movie_search_base_uri = 'https://api.themoviedb.org/3'
        self.poster_cover_uri = 'http://image.tmdb.org/t/p/w185'

    def get_movies_by_title(self, title: str) -> List[Movie]:
        payload = {'query': title,
                   'api_key': 'secret token',
                   'language': 'en-US',
                   'include_adult': False}

        response = requests.get(f'{self.movie_search_base_uri}/search/movie', params=payload)

        response.raise_for_status()
        response_body = response.json()

        results = response_body.get('results')
        books = [self.movie_from_tmdb_result(result=result) for result in results]
        return books

    def movie_from_tmdb_result(self, result: Dict) -> Movie:
        clean_result = {}

        clean_result['title'] = result.get('original_title', None).title()
        clean_result['release_date'] = result.get('release_date', None)
        clean_result['poster_url'] = f"{self.poster_cover_uri}{result.get('poster_path')}" if result.get('poster_path') else None

        return Movie.from_dict(clean_result)
