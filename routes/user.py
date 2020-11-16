from datetime import datetime

from flask import current_app, jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.user import ConsumptionStatus, Consumption
from db.helpers import MEDIAS, get_consumption_records

user = Blueprint("user", __name__)

engine = sa.create_engine('postgresql://zoe:123@localhost/goodtimes', echo=True)
Session = sessionmaker(bind=engine)



@user.route("/user/<int:user_id>/media/<media_type>", methods=["POST"])
def add_media(user_id, media_type):
    """
    Endpoint for adding media_type to consumption table under given user id. Posted body must include status
    of media consumption.
    :param user_id:
    :param media_type: book, movie or tv
    :return:
    """
    # TODO: index source id in media tables
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
        # TODO: update message
        return jsonify("Object needs at least fields source, source_id, and title"), 400

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
                                  status=status,
                                  created=datetime.utcnow())

    session.add(consumption_rec)

    session.commit()
    session.close()
    return "success", 200


@user.route("/user/<int:user_id>/media/<media_type>", methods=["GET"])
def add_book(user_id, media_type):
    """
    Endpoint for getting all media associated with a given user.
    :param user_id:
    :param media_type: book, movie or tv
    :return:
    """
    #TODO: should we be able to get all media together?
    record_results = get_consumption_records(user_id, media_type, Session())

    result = []
    for consumption, media in record_results:
        c = consumption.to_dict()
        # Remove id and media_id associated with consumption as not necessary
        c.pop('id'), c.pop('media_id')
        c['media'] = media.to_dict()
        result.append(c)

    return jsonify(result), 200
