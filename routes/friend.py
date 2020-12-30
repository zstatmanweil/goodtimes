from datetime import datetime

from pyhocon import ConfigFactory

from flask import current_app, jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.friend import Friend, FriendStatus

config = ConfigFactory.parse_file('config/config')
friend = Blueprint("friend", __name__)

engine = sa.create_engine(config.postgres_db, echo=True)
Session = sessionmaker(bind=engine)


@friend.route("/friend", methods=["POST"])
def add_friend_link():
    """
    Endpoint for adding friend link. Posted body:
    {
    "requester_id": int,
    "requested_id": int,
    "status": str
    }
    :return:
    """
    session = Session()

    request_body = request.get_json()

    # Validate post body
    status = request_body.get('status')
    if not status or status not in [v.value for v in FriendStatus]:
        return "Request body needs a status of 'requested', 'accepted', 'ignored' or 'unfriend", 400

    request_body['created'] = datetime.utcnow()

    try:
        friend = Friend.from_dict(request_body)
    except KeyError:
        return jsonify("Object missing required fields."), 400

    # Check if friend link is already in the database

    # Add friend to DB
    session.add(friend)
    friend_json = friend.to_json()
    session.commit()
    session.close()

    return friend_json, 200



