from datetime import date
from flask import request, Blueprint
from flask_cors import cross_origin

from models.movies import Movie
from server import requires_auth
from wrappers.tmdb import TMDB

movies = Blueprint("movies", __name__)


@movies.route("/movies", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def search_movies():
    args = request.args
    title = args.get('title', None)

    tmdb = TMDB()
    result = tmdb.get_movies_by_title(title)
    result = sorted(result, key=lambda m: date(1900, 1, 1) if not m.release_date else m.release_date, reverse=True)
    return Movie.schema().dumps(result, many=True)
