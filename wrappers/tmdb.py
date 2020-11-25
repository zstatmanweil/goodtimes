from datetime import datetime
from typing import List, Dict

import requests

from models.movies import Movie
from models.tv import TV
from secrets import TMDB_TOKEN


class TMDB:
    def __init__(self):
        self.search_base_uri = 'https://api.themoviedb.org/3'
        self.poster_cover_uri = 'http://image.tmdb.org/t/p/w185'
        self.api_key = TMDB_TOKEN

    def get_movies_by_title(self, title: str) -> List[Movie]:
        payload = {'query': title,
                   'api_key': self.api_key,
                   'language': 'en-US',
                   'include_adult': False}

        response = requests.get(f'{self.search_base_uri}/search/movie', params=payload)

        response.raise_for_status()
        response_body = response.json()

        results = response_body.get('results')
        books = [self.movie_from_tmdb_result(result=result) for result in results]
        return books

    def movie_from_tmdb_result(self, result: Dict) -> Movie:
        clean_result = {}

        clean_result['source_id'] = str(result.get('id', None))
        clean_result['source'] = 'tmdb'
        clean_result['title'] = result.get('title', None).title()
        clean_result['release_date'] = datetime.strptime(result.get('release_date'), '%Y-%m-%d').date() if result.get('release_date') else None
        clean_result['poster_url'] = f"{self.poster_cover_uri}{result.get('poster_path')}" if result.get('poster_path') else None

        return Movie.from_dict(clean_result)

    def get_tv_by_title(self, title: str) -> List[Movie]:
        payload = {'query': title,
                   'api_key': self.api_key,
                   'language': 'en-US',
                   'include_adult': False}

        response = requests.get(f'{self.search_base_uri}/search/tv', params=payload)

        response.raise_for_status()
        response_body = response.json()

        results = response_body.get('results')
        books = [self.tv_from_tmdb_result(result=result) for result in results]
        return books

    def tv_from_tmdb_result(self, result: Dict) -> Movie:
        clean_result = {}

        id = result.get('id', None)

        clean_result['source_id'] = str(id)
        clean_result['source'] = 'tmdb'
        clean_result['title'] = result.get('name', None)
        clean_result['first_air_date'] = datetime.strptime(result.get('first_air_date'), '%Y-%m-%d').date() if result.get('first_air_date') else None
        clean_result['poster_url'] = f"{self.poster_cover_uri}{result.get('poster_path')}" if result.get('poster_path') else None
        clean_result['networks'] = self.get_tv_network_by_id(id)

        return TV.from_dict(clean_result)

    def get_tv_network_by_id(self, tmdb_id: int) -> List[str]:
        payload = {'api_key': self.api_key,
                   'language': 'en-US'}

        response = requests.get(f'{self.search_base_uri}/tv/{tmdb_id}', params=payload)
        response.raise_for_status()
        response_body = response.json()

        networks = [d.get('name') for d in response_body.get('networks')]

        return networks
