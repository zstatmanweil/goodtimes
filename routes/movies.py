from flask import jsonify, request, Blueprint

from hooks.tmdb import TMDB

movies = Blueprint("movies", __name__)


@movies.route("/movies", methods=["GET"])
def search_books():
    args = request.args
    title = args.get('title', None)

    tmdb = TMDB()
    result = tmdb.get_movies_by_title(title)
    return jsonify(sorted(result, key=lambda m: m.release_date, reverse=True))
