from flask import request, Blueprint


DATABASE = 'friends'

books = Blueprint("books", __name__)


@books.route("/books", methods=["POST"])
def search_books():
    args = request.args
    book_title = args.get('title', None)
    return f"You searched book title {book_title}!"

