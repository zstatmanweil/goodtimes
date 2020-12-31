from pyhocon import ConfigFactory
from datetime import datetime

from flask import current_app, jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.consumption import Consumption, ConsumptionStatus
from models.recommendation import RecommendationStatus, Recommendation
from models.user import User
from db.helpers import MEDIAS, get_consumption_records, get_recommendation_records, get_users_and_friend_statuses

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


@user.route("/user/<int:user_id>/friends", methods=["GET"])
def get_user_friends(user_id):
    # TODO: get user's friends rather than all users
    session = Session()
    user_results = session.query(User).filter(User.id != user_id).all()
    session.close()
    return User.schema().dumps(user_results, many=True)


@user.route("/users", methods=["GET"])
def get_user_and_status_by_email():
    args = request.args
    email_substring = args.get('email', '')
    user_id = args.get('user_id')

    session = Session()
    user_results = get_users_and_friend_statuses(user_id, email_substring, session)

    final = []
    for user, status in user_results:
        u = user.to_dict()
        u['status'] = status
        final.append(u)
    session.close()

    return jsonify(final)


@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
def add_media_to_profile(user_id, media_type):
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
def get_consumed_media_by_media_type(user_id, media_type):
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
    Endpoint for adding a recommendation for a given media type. Post body:
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

    # get media_id
    media_class = MEDIAS.get(media_type)
    db_resp = session.query(media_class).filter_by(source_id=request_body.get('source_id')).first()
    request_body['media_id'] = db_resp.id

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


@user.route("/user/<int:user_id>/recommendations", methods=["GET"])
def get_recommended_media(user_id):
    """
    Endpoint for getting all media associated with a given user.
    :param user_id:
    :return: media object + media_type + recommender_id + recommender_username, e.g.,
    {
        "media": {"author_names": [
                    "Holly Black"
                    ],
                    "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
                    "id": 2,
                    "publish_year": 2020,
                    "source": "open library",
                    "source_id": "0123",
                    "title": "The Queen Of Nothing"},
        "media_type": "book",
        "recommender_id": 1,
        "recommender_username": "strickinato"
    },
    """
    session = Session()

    final = []
    for media in MEDIAS.keys():
        print(media)
        # TODO: modify to only make one call to DB
        record_results = get_recommendation_records(user_id, media, session)
        for recommendation, media_class, user_class, status in record_results:
            m = media_class.to_dict()
            m['status'] = status
            media_result = {'media': m,
                            "media_type": media,
                            'recommender_id': user_class.id,
                            'recommender_username': user_class.username,
                            'created': recommendation.created}
            final.append(media_result)

    session.close()
    return jsonify(sorted(final, key=lambda m: m.get('created'), reverse=True)), 200