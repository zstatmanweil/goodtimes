from flask import jsonify, request, Blueprint
from flask_cors import cross_origin

from server import requires_auth
from wrappers.google_books import GoogleBooks

books = Blueprint("books", __name__)


@books.route("/books", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def search_books():
    args = request.args
    title = args.get('title', None)

    google_books = GoogleBooks()
    result = google_books.get_books_by_query(title)
    return jsonify(result)

