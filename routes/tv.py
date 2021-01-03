from datetime import date

from flask import request, Blueprint

from models.tv import TV
from wrappers.tmdb import TMDB

tv = Blueprint("tv", __name__)


@tv.route("/tv", methods=["GET"])
def search_tv():
    args = request.args
    title = args.get('title', None)

    tmdb = TMDB()
    result = tmdb.get_tv_by_title(title)
    result = sorted(result, key=lambda m: date(1900, 1, 1) if not m.first_air_date else m.first_air_date, reverse=True)
    return TV.schema().dumps(result, many=True)
