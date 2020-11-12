from flask import jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.books import Book
from models.user import ConsumptionStatus

user = Blueprint("user", __name__)

engine = sa.create_engine('postgresql://zoe:123@localhost/goodtimes', echo=True)
Session = sessionmaker(bind=engine)

medias = {
    "book": Book
}

@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
def add_book(user_id, media_type):
    # json body includes status
    # {
    #     status: str
    #     media body
    #
    # }
    # check if in book table in database, if not add, then add to user table. Make sure to index source id
    session = Session()

    request_body = request.get_json()
    status = request_body.get('status')
    media_class = medias.get(media_type)

    if not status or status not in [v.value for v in ConsumptionStatus]:
        return "Request body needs a status of 'want to consume', 'consuming', 'finished', or 'abandoned'", 400
    request_body.pop('status')

    try:
        media_item = media_class.from_dict(request_body)
    except KeyError:
        #TODO: update message
        return jsonify("Object needs at least fields source, source_id, and title")

    # check if media item is in database
    db_resp = session.query(media_class).filter_by(source_id=media_item.source_id).first()

    # if not in database, add media item to appropriate table
    if not db_resp:
        # TODO: figure out logging with blueprints
        print("Media not in database, adding media with source_id %s to database", media_item.source_id)
        session.add(media_item)
        # get new item
        db_resp = session.query(media_class).filter_by(source_id=media_item.source_id).first()

    media_id = db_resp.id
    print(media_id)
    # Add media item to consumption table

    session.commit()
    session.close()
    return "success", 200

