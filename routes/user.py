from pyhocon import ConfigFactory
from datetime import datetime

from flask import current_app, jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.consumption import Consumption, ConsumptionStatus
from models.recommendation import RecommendationStatus, Recommendation
from models.user import User
from db.helpers import MEDIAS, get_consumption_records

config = ConfigFactory.parse_file('config/config')
user = Blueprint("user", __name__)

engine = sa.create_engine(config.postgres_db, echo=True)
Session = sessionmaker(bind=engine)

@user.route("/user/<int:user_id>", methods=["GET"])
def get_user(user_id):
    session = Session()
    user_result = session.query(User).filter_by(id=user_id).first()
    session.close()
    if not user_result:
        return f"user (id {user_id}) does not exist", 404
    return user_result.to_json()


@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
def add_media(user_id, media_type):
    """
    Endpoint for adding media to consumption table under given user id. Posted body is media object + status, e.g.:
    {
        "author_names": ["Holly Black"],
        "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
        "publish_year": 2020,
        "source": "open library",
        "source_id": "0123",
        "title": "The Queen Of Nothing",
        "status": "finished"
    }
    :param user_id:
    :param media_type: book, movie or tv
    :return:
    """
    session = Session()

    request_body = request.get_json()
    status = request_body.get('status')
    media_class = MEDIAS.get(media_type)

    if not status or status not in [v.value for v in ConsumptionStatus]:
        return "Request body needs a status of 'want to consume', 'consuming', 'finished', or 'abandoned'", 400
    request_body.pop('status')

    try:
        media_item = media_class.from_dict(request_body)
    except KeyError:
        return jsonify("Object is missing required fields."), 400

    # check if media item is in database
    db_resp = session.query(media_class).filter_by(source_id=media_item.source_id).first()

    # if not in database, add media item to appropriate table
    if not db_resp:
        current_app.logger.info(
            f"Media not in database, adding media with source_id {media_item.source_id} to database")
        session.add(media_item)
        session.flush()
        media_id = media_item.id

    else:
        media_id = db_resp.id

    current_app.logger.info(
        f"Recording media with source_id {media_item.source_id} in consumption table {user_id} with status {status} (user id {user_id})")
    # Add media item to consumption table
    consumption_rec = Consumption(user_id=user_id,
                                  media_type=media_type,
                                  media_id=media_id,
                                  source_id=media_item.source_id,
                                  status=status,
                                  created=datetime.utcnow())

    session.add(consumption_rec)
    consumption_resp = consumption_rec.to_json()
    session.commit()
    session.close()
    return consumption_resp, 200


@user.route("/user/<int:user_id>/media/<media_type>", methods=["GET"])
def get_media(user_id, media_type):
    """
    Endpoint for getting all media associated with a given user.
    :param user_id:
    :param media_type: book, movie or tv
    :return: media object + status, e.g.,
    {
        "author_names": [
            "Holly Black"
        ],
        "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
        "id": 2,
        "publish_year": 2020,
        "source": "open library",
        "source_id": "0123",
        "status": "finished",
        "title": "The Queen Of Nothing"
    },
    """
    session = Session()
    record_results = get_consumption_records(user_id, media_type, session)

    result = []
    for consumption, media in record_results:
        c = consumption.to_dict()
        # Remove id, media_id, and user_id associated with consumption as not necessary
        # TODO: this is just temporary - need to figure out what to return
        c.pop('id'), c.pop('media_id'), c.pop('user_id'), c.pop('media_type'), c.pop('created')
        c.update(media.to_dict())
        result.append(c)

    session.close()
    return jsonify(result), 200


@user.route("/media/<media_type>/recommendation", methods=["POST"])
def add_recommended_media(media_type):
    """
    Endpoint for adding a recommendation for a given media type. Posted body:
    {
        "recommender_user_id": int
        "recommended_user_id": int
        "media_id": int
        "source_id": string
        "status": string
    }
    :param user_id:
    :param media_type: book, movie or tv
    :return:
    """
    session = Session()

    request_body = request.get_json()
    status = request_body.get('status')

    if not status or status not in [v.value for v in RecommendationStatus]:
        return "Request body needs a status of 'pending' or 'ignored'", 400

    # Add media type and created
    request_body['media_type'] = media_type
    request_body['created'] = datetime.utcnow()

    try:
        rec = Recommendation.from_dict(request_body)
    except KeyError:
        return jsonify("Object missing required fields."), 400

    # add recommendation to DB
    session.add(rec)
    rec_json = rec.to_json()
    session.commit()
    session.close()
    return rec_json, 200
