from flask import jsonify, request, Blueprint

from hooks.tmdb import TMDB

tv = Blueprint("tv", __name__)


@tv.route("/tv", methods=["GET"])
def search_tv():
    args = request.args
    title = args.get('title', None)

    tmdb = TMDB()
    result = tmdb.get_tv_by_title(title)
    return jsonify(sorted(result, key=lambda m: m.first_air_date, reverse=True))
