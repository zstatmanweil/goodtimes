from flask import jsonify, request, Blueprint

from hooks.open_lib import OpenLibrary
from models.books import CoverSize

books = Blueprint("books", __name__)


@books.route("/books", methods=["GET"])
def search_books():
    args = request.args
    title = args.get('title', None)

    open_library = OpenLibrary()
    result = open_library.get_books_by_title(title, cover_image_size=CoverSize.MEDIUM)
    return jsonify(result)

