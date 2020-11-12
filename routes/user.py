from datetime import datetime

from flask import jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.books import Book
from models.movies import Movie
from models.tv import TV
from models.user import ConsumptionStatus, Consumption

user = Blueprint("user", __name__)

engine = sa.create_engine('postgresql://zoe:123@localhost/goodtimes', echo=True)
Session = sessionmaker(bind=engine)

medias = {
    "book": Book,
    "movie": Movie,
    "tv": TV
}


@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
def add_book(user_id, media_type):
    """
    json body includes status
    {
        status: str
        media body

    }
    """
    # TODO: index source id in media tables
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
        print(f"Media not in database, adding media with source_id {media_item.source_id} to database" )
        session.add(media_item)
        session.flush()
        media_id = media_item.id

    else:
        media_id = db_resp.id

    # Add media item to consumption table
    consumption_rec = Consumption(user_id=user_id,
                                  media_type=media_type,
                                  media_id=media_id,
                                  status=status,
                                  created=datetime.utcnow())

    session.add(consumption_rec)

    session.commit()
    session.close()
    return "success", 200

