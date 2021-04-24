from datetime import datetime

from flask_cors import cross_origin
from pyhocon import ConfigFactory

from flask import jsonify, request, Blueprint
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from db.helpers import get_user_friends, get_user_friend_requests
from models.friend import Friend, FriendStatus
from models.user import User
from server import requires_auth
from config import DATABASE_URL

friend = Blueprint("friend", __name__)

engine = sa.create_engine(DATABASE_URL, echo=True)
Session = sessionmaker(bind=engine)


@friend.route("/friend", methods=["POST"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
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


@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
@friend.route("/user/<int:user_id>/friends", methods=["GET"])
def get_friends(user_id):
    """
    Get all a user's friends.
    :param user_id:
    :return:
    """
    session = Session()
    user_results = get_user_friends(user_id, session)
    session.close()
    return User.schema().dumps(user_results, many=True)


@friend.route("/user/<int:user_id>/requests", methods=["GET"])
@cross_origin(headers=["Content-Type", "Authorization"])
@requires_auth
def get_friend_requests(user_id):
    """
    Get all a user's friends.
    :param user_id:
    :return:
    """
    session = Session()
    user_results = get_user_friend_requests(user_id, session)
    session.close()
    return User.schema().dumps(user_results, many=True)

