from datetime import date
from flask import request, Blueprint

from models.movies import Movie
from wrappers.tmdb import TMDB

movies = Blueprint("movies", __name__)


@movies.route("/movies", methods=["GET"])
def search_movies():
    args = request.args
    title = args.get('title', None)

    tmdb = TMDB()
    result = tmdb.get_movies_by_title(title)
    result = sorted(result, key=lambda m: date(1900, 1, 1) if not m.release_date else m.release_date, reverse=True)
    return Movie.schema().dumps(result, many=True)
