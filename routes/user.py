from flask_cors import cross_origin
from pyhocon import ConfigFactory
from datetime import datetime, date

from flask import current_app, jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker
from werkzeug.exceptions import abort

from models.consumption import Consumption, ConsumptionStatus
from models.recommendation import RecommendationStatus, Recommendation
from models.user import User
from db.helpers import MEDIAS, get_consumption_records, get_users_and_friend_statuses, \
    get_records_recommended_by_user, get_records_recommended_to_user, get_overlapping_records, get_friend_event_records
from routes.helpers import get_time_diff_hrs
from server import requires_auth

config = ConfigFactory.parse_file('config/config')
user = Blueprint("user", __name__)

engine = sa.create_engine(config.postgres_db, echo=True)
Session = sessionmaker(bind=engine)


@user.route("/user", methods=["POST"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def verify_user():
    """ Checks if a user is in database, and if not, adds them. Post body:
    {
        auth0_sub : str
        first_name: str
        last_name: str
        full_name: str
        email: str
        picture: str
    }
    :return: User object
    """
    request_body = request.get_json()

    session = Session()
    try:
        user = User.from_dict(request_body)
    except KeyError:
        abort(400, description="object is missing required fields")

    # check if user is in database
    db_resp = session.query(User).filter_by(auth0_sub=user.auth0_sub).first()
    print("DB_RESP", db_resp)
    # if not in database, add user
    if not db_resp:
        current_app.logger.info(
            f"User not in database, adding user with sub {user.auth0_sub} to database")
        session.add(user)
        session.commit()
        db_resp = session.query(User).filter_by(auth0_sub=user.auth0_sub).first()

    session.close()

    return db_resp.to_json()


@user.route("/user/<int:user_id>", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_user(user_id):
    """
    Get user object by id
    :param user_id:
    :return: User object
    """
    session = Session()
    user_result = session.query(User).filter_by(id=user_id).first()
    session.close()
    if not user_result:
        abort(404, description=f"user (id {user_id}) does not exist")
    return user_result.to_json()


@user.route("/users", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_user_and_status_by_email():
    """
    Search for a user by email and with user ID of user conducting the search. User record and status of friendship
    between user conducting the search and user associated with email.
    :return: Example
    {
        "id": 1,
        "auth0_sub": "123",
        "first_name": "zoe"
        "last_name": "fakename",
        "full_name": "zoe fakename",
        "email": "zoefakename@yahoo.com",
        "created": 1611190613.837367,
        "picture": "zoefakename.jpg",
        "status": "pending"
    }
    """
    args = request.args
    # Email search
    email_substring = args.get('email', '')
    # User ID of user conducting the search
    user_id = args.get('user_id')

    session = Session()
    user_results = get_users_and_friend_statuses(user_id, email_substring, session)

    final = []
    for user, status in user_results:
        record = dict()
        record['user'] = user.to_dict()
        # Status of friendship between searching user and the user associated with the email
        record['status'] = status
        final.append(record)
    session.close()

    return jsonify(final)


@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
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
        abort(400,
              description="Request body needs a status of 'want to consume', 'consuming', 'finished', or 'abandoned'")
    request_body.pop('status')

    try:
        media_item = media_class.from_dict(request_body)
    except KeyError:
        abort(400, description="object is missing required fields")

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
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_consumed_media_by_media_type(user_id, media_type):
    """
    Endpoint for getting all media associated with a given user.
    :param user_id:
    :param media_type: book, movie or tv
    :return: List of media object + status, e.g.,
    [{
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
    }]
    """
    session = Session()
    record_results = get_consumption_records(user_id, media_type, session)

    result = []
    for consumption, media in record_results:
        c = consumption.to_dict()
        # Remove id, media_id, and user_id associated with consumption as not necessary
        c.pop('id'), c.pop('media_id'), c.pop('user_id'), c.pop('media_type'), c.pop('created')
        c.update(media.to_dict())
        result.append(c)

    session.close()
    return jsonify(result), 200


@user.route("/media/<media_type>/recommendation", methods=["POST"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def add_recommended_media(media_type):
    """
    Endpoint for adding a recommendation for a given media type. Post body:
    {
        "recommender_user_id": int
        "recommended_user_id": int
        "source_id": string
        "status": string
    }
    :param media_type: book, movie or tv
    :return: Recommendation object
    """
    session = Session()

    request_body = request.get_json()
    status = request_body.get('status')

    if not status or status not in [v.value for v in RecommendationStatus]:
        return"Request body needs a status of 'pending' or 'ignored'", 400

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
        return abort(400, description="Object missing required fields")

    # add recommendation to DB
    session.add(rec)
    rec_json = rec.to_json()
    session.commit()
    session.close()
    return rec_json, 200


@user.route("/user/<int:user_id>/recommendations/<media_type>", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_media_recommended_to_user(user_id, media_type):
    """
    Endpoint for getting specific media recommended to a user and that user's consumption status associated
    with the media.
    :param user_id:
    :param media_type: book, movie or tv
    :return: List of media object + media_type + recommender_id + recommender_full_name, e.g.,
    [{
        "media": {"author_names": [
                    "Holly Black"
                    ],
                    "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
                    "id": 2,
                    "publish_year": 2020,
                    "source": "open library",
                    "source_id": "0123",
                    "title": "The Queen Of Nothing",
                    "status": "consuming"},
        "media_type": "book",
        "recommender_id": 1,
        "recommender_full_name": "Aaron Strick"
    }]
    """
    session = Session()

    final = []
    record_results = get_records_recommended_to_user(user_id, media_type, session)
    for recommendation, media_class, user_class, status in record_results:
        m = media_class.to_dict()
        m['status'] = status
        media_result = {'media': m,
                        "media_type": media_type,
                        'recommender_id': user_class.id,
                        'recommender_full_name': user_class.full_name,
                        'created': recommendation.created}
        final.append(media_result)

    session.close()
    return jsonify(sorted(final, key=lambda m: m.get('created'), reverse=True)), 200


@user.route("/user/<int:user_id>/recommended/<media_type>", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_media_recommended_by_user(user_id, media_type):
    """
    Endpoint for getting specific media recommended by a user.
    :param user_id:
    :param media_type
    :return: List of media object + media_type + recommended_id + recommended_full_name, e.g.,
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
        "recommended_id": 2,
        "recommended_full_name": "full_name"
    },
    """
    session = Session()

    final = []
    record_results = get_records_recommended_by_user(user_id, media_type, session)
    for recommendation, media_class, user_class in record_results:
        m = media_class.to_dict()
        media_result = {'media': m,
                        "media_type": media_type,
                        'recommended_id': user_class.id,
                        'recommended_full_name': user_class.full_name,
                        'created': recommendation.created}
        final.append(media_result)

    session.close()
    return jsonify(sorted(final, key=lambda m: m.get('created'), reverse=True)), 200


@user.route("/overlaps/<media_type>/<int:primary_user_id>/<int:other_user_id>", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_overlapping_media(media_type, primary_user_id, other_user_id):
    """
    Endpoint for getting overlapping media - media that is is on both the primary_user_id and other_user_id's
    media lists.
    :param primary_user_id: ID of primary user looking for overlapping media
    :param other_user_id: ID of user the primary user wants to find overlaps with
    :param media_type
    :return: Returns list of media object with other user ID and other user's consumption status of
    overlapping media, e,g,,
     {
        "media": { "author_names": [
                    "Holly Black"
                    ],
                "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
                "id": 2,
                "publish_year": 2020,
                "source": "open library",
                "source_id": "0123",
                "title": "The Queen Of Nothing"
                "status": "consuming"}
        "media_type": "book",
        "other_user_id": 1,
        "other_user_status": "finished"

    }
    """
    if media_type not in MEDIAS.keys():
        abort(400, "Media_type must be 'book', 'movie', or tv")

    session = Session()
    record_results = get_overlapping_records(primary_user_id, other_user_id, media_type, session)
    session.close()

    final = []
    for record in record_results:
        print(record)
        record_dict = dict(record)
        if record_dict.get('first_air_date'):
            record_dict['first_air_date'] = date.isoformat(record_dict['first_air_date'])
        record_dict['status'] = record_dict.pop("primary_user_status")
        other_user_status = record_dict.pop("other_user_status")
        m = {"media": record_dict,
             "media_type": media_type,
             "other_user_id": other_user_id,
             "other_user_status": other_user_status
             }
        final.append(m)

    return jsonify(sorted(final, key=lambda m: m.get('media').get('title'))), 200


@user.route("/user/<int:user_id>/friend/events", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_friend_events(user_id):
    """
    Endpoint for getting all events associated with a user's friends.
    :param user_id:
    :return: media object + status, e.g.,
    {
        "media" : { "author_names": [
                        "Holly Black"
                    ],
                    "cover_url": "http://covers.openlibrary.org/b/id/10381918-M.jpg",
                    "id": 2,
                    "publish_year": 2020,
                    "source": "open library",
                    "source_id": "0123",
                    "status": "finished",
                    "title": "The Queen Of Nothing" }
        "media_type": "book",
        "user_id" : 1,
        "full_name" : Aaron Strick,
        "status" : "consuming"
        "created" : datetime
    },
    """
    session = Session()
    record_results = get_friend_event_records(user_id, session)

    final_results = []
    for media_set in record_results:
        for media_class, consumption_class, user_class in media_set:
            m = media_class.to_dict()
            media_result = {'media': m,
                            "media_type": consumption_class.media_type,
                            'user_id': user_class.id,
                            'full_name': user_class.full_name,
                            'status': consumption_class.status,
                            'created': consumption_class.created,
                            'time_since': get_time_diff_hrs(consumption_class.created)}

            final_results.append(media_result)

    session.close()
    return jsonify(sorted(final_results, key=lambda m: m.get('time_since'))), 200




