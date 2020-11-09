from datetime import datetime

from flask import jsonify, request, Blueprint
import sqlalchemy as sa

from models.books import Book
from models.user import ConsumptionStatus

books = Blueprint("user", __name__)


@books.route("/user/<int: user_id>/media/<str: media_type>", methods=["POST"])
def add_book(user_id, media_type):
    # json body includes status
    # {
    #     status: str
    #     media body
    #
    # }
    # check if in book table in database, if not add, then add to user table. Make sure to index source id
    request_body = request.get_json()
    status = request_body.get('status')

    if not status or status not in [v.value for v in ConsumptionStatus]:
        return "Request body needs a status of 'want to consume', 'consuming', 'finished', or 'abandoned'", 400
    request_body.pop('status')

    if media_type == 'book':
        try:
            book = Book.from_dict(request_body)
        except KeyError:
            return jsonify("Object needs at least fields source_id, source, title")

    # Search if book is in table - get source_id

    # record = dict(
    #     user_id=user_id,
    #     media_type="book",
    #     media_id=book_id,
    #     status=status,
    #     timestamp=datetime.now()
    # )
    return 200