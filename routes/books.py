from flask import jsonify, request, Blueprint

from wrappers.google_books import GoogleBooks

books = Blueprint("books", __name__)


@books.route("/books", methods=["GET"])
def search_books():
    args = request.args
    title = args.get('title', None)

    google_books = GoogleBooks()
    result = google_books.get_books_by_title(title)
    return jsonify(result)

