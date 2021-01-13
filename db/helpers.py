from typing import List, Tuple

from sqlalchemy import and_, or_, desc, func
from sqlalchemy.orm import session

from models.books import Book
from models.movies import Movie
from models.recommendation import Recommendation
from models.tv import TV
from models.consumption import Consumption
from models.user import User
from models.friend import Friend, FriendStatus

MEDIAS = {
    "book": Book,
    "movie": Movie,
    "tv": TV
}


def get_consumption_records(user_id: int, media_type: str, session: session) -> List[Tuple]:
    """
    Get most recent records for all media associated with a user.
    :param user_id:
    :param media_type:
    :param session:
    :return: Returns a tuple of the Consumption object and Media object
    """
    media_class = MEDIAS.get(media_type)
    # Get most recent record for each item in consumption table
    subq = session.query(Consumption.user_id, Consumption.media_id, Consumption.media_type,
                         func.max(Consumption.created).label("max_created")) \
        .group_by(Consumption.user_id, Consumption.media_id, Consumption.media_type) \
        .subquery()

    # Get most recent consumption data for selected media for user
    results = session.query(Consumption, media_class) \
        .filter_by(user_id=user_id, media_type=media_type) \
        .join(subq, and_(Consumption.media_id == subq.c.media_id,
                         Consumption.media_type == subq.c.media_type,
                         Consumption.created == subq.c.max_created)) \
        .join(media_class, media_class.id == Consumption.media_id) \
        .order_by(desc(Consumption.created)) \
        .all()

    return results


def get_records_recommended_to_user(user_id: int, media_type: str, session: session) -> List[Tuple]:
    """
    Get recommendations to a user for a specific media type.
    :param user_id:
    :param media_type:
    :param session:
    :return: Returns a tuple of the Recommendation object, Media object and User object
    """
    media_class = MEDIAS.get(media_type)
    # Get most recent record for each item in recommendation table
    rec_subq = session.query(Recommendation.recommended_user_id, Recommendation.recommender_user_id,
                             Recommendation.media_id, Recommendation.media_type,
                         func.max(Recommendation.created).label("max_created")) \
        .group_by(Recommendation.recommended_user_id, Recommendation.recommender_user_id,
                  Recommendation.media_id, Recommendation.media_type) \
        .subquery()

    cons_subq = session.query(Consumption.user_id, Consumption.media_id, Consumption.media_type,
                         func.max(Consumption.created).label("max_created")) \
        .group_by(Consumption.user_id, Consumption.media_id, Consumption.media_type) \
        .subquery()

    cons_combined_subq = session.query(Consumption).join(cons_subq, and_(Consumption.user_id == cons_subq.c.user_id,
                                                                         Consumption.media_id == cons_subq.c.media_id,
                                                                         Consumption.media_type == cons_subq.c.media_type,
                                                                         Consumption.created == cons_subq.c.max_created)).subquery()

    # Get most recent recommendation data for selected media for user
    results = session.query(Recommendation, media_class, User, cons_combined_subq.c.status) \
        .filter_by(recommended_user_id=user_id, media_type=media_type) \
        .join(rec_subq, and_(Recommendation.media_id == rec_subq.c.media_id,
                             Recommendation.media_type == rec_subq.c.media_type,
                             Recommendation.created == rec_subq.c.max_created)) \
        .join(media_class, media_class.id == Recommendation.media_id) \
        .join(User, User.id == Recommendation.recommender_user_id) \
        .join(cons_combined_subq, and_(Recommendation.media_id == cons_combined_subq.c.media_id,
                                Recommendation.media_type == cons_combined_subq.c.media_type,
                                Recommendation.recommended_user_id == cons_combined_subq.c.user_id), isouter=True) \
        .order_by(desc(Recommendation.created)) \
        .all()

    return results


def get_records_recommended_by_user(user_id: int, media_type: str, session: session) -> List[Tuple]:
    """
    Get recommendations to a user for a specific media type.
    :param user_id:
    :param media_type:
    :param session:
    :return: Returns a tuple of the Recommendation object, Media object and User object
    """
    media_class = MEDIAS.get(media_type)
    # Get most recent record for each item in recommendation table
    rec_subq = session.query(Recommendation.recommended_user_id, Recommendation.recommender_user_id,
                             Recommendation.media_id, Recommendation.media_type,
                         func.max(Recommendation.created).label("max_created")) \
        .group_by(Recommendation.recommended_user_id, Recommendation.recommender_user_id,
                  Recommendation.media_id, Recommendation.media_type) \
        .subquery()

    # Get most recent recommendation data for selected media for user
    results = session.query(Recommendation, media_class, User) \
        .filter_by(recommender_user_id=user_id, media_type=media_type) \
        .join(rec_subq, and_(Recommendation.media_id == rec_subq.c.media_id,
                             Recommendation.media_type == rec_subq.c.media_type,
                             Recommendation.created == rec_subq.c.max_created)) \
        .join(media_class, media_class.id == Recommendation.media_id) \
        .join(User, User.id == Recommendation.recommended_user_id) \
        .order_by(desc(Recommendation.created)) \
        .all()

    return results


def get_users_and_friend_statuses(user_id: int, email_substring: str, session: session) -> List[Tuple]:
    """
    Get all users that have an email containing the email substring along with the friendship status,
    if there is one.
    :param user_id:
    :param email_substring:
    :param session:
    :return:
    """
    max_friend_link_subq = session.query(Friend.requester_id, Friend.requested_id, func.max(Friend.created).label("max_created")) \
        .group_by(Friend.requester_id, Friend.requested_id) \
        .subquery()

    friend_subq = session.query(Friend).filter(or_(Friend.requester_id == user_id, Friend.requested_id == user_id)) \
        .join(max_friend_link_subq, and_(Friend.requester_id == max_friend_link_subq.c.requester_id,
                                         Friend.requested_id == max_friend_link_subq.c.requested_id,
                                         Friend.created == max_friend_link_subq.c.max_created)) \
        .subquery()

    results = session.query(User, friend_subq.c.status).filter(User.email.contains(email_substring))\
        .filter(User.id != user_id) \
        .join(friend_subq, or_(User.id == friend_subq.c.requester_id,
                               User.id == friend_subq.c.requested_id), isouter=True)\
        .all()

    return results


def get_user_friends(user_id: int, session: session) -> List[Tuple]:
    """
    Get all a user's friends
    :param user_id:
    :param session:
    :return:
    """

    friend_subq = create_user_friends_subquery(user_id, session)

    results = session.query(User).filter(User.id != user_id) \
        .join(friend_subq, or_(User.id == friend_subq.c.requester_id,
                               User.id == friend_subq.c.requested_id)) \
        .all()

    return results


def get_user_friend_requests(user_id: int, session: session) -> List[Tuple]:
    """
    Get all a user's friend requests.
    :param user_id:
    :param session:
    :return:
    """

    max_friend_link_subq = session.query(Friend.requester_id, Friend.requested_id,
                                         func.max(Friend.created).label("max_created")) \
        .group_by(Friend.requester_id, Friend.requested_id) \
        .subquery()

    friend_subq = session.query(Friend).filter(and_(Friend.requested_id == user_id,
                                                    Friend.status == FriendStatus.REQUESTED.value)) \
        .join(max_friend_link_subq, and_(Friend.requester_id == max_friend_link_subq.c.requester_id,
                                         Friend.requested_id == max_friend_link_subq.c.requested_id,
                                         Friend.created == max_friend_link_subq.c.max_created)) \
        .subquery()

    results = session.query(User).filter(User.id != user_id)\
        .join(friend_subq, or_(User.id == friend_subq.c.requester_id,
                               User.id == friend_subq.c.requested_id))\
        .all()

    return results


def get_overlapping_records(primary_user_id: int, other_user_id: int, media_type: str, status: str, session: session) -> List:
    """
    Get media records of a given status that two users have in common.
    :param primary_user_id: The logged in user.
    :param other_user_id: The user the logged in user is veewing.
    :param media_type: book, movie or tv
    :param status: want to consume, consuming, finished, abandoned
    :param session:
    :return: media class object
    """
    media_class = MEDIAS.get(media_type)
    # Get most recent record for each item in consumption table associated with either one of the users.
    consumption_subq = session.query(Consumption.user_id, Consumption.media_id, Consumption.media_type,
                         func.max(Consumption.created).label("max_created")) \
        .filter(or_(Consumption.user_id == primary_user_id, Consumption.user_id == other_user_id)) \
        .filter(Consumption.media_type == media_type) \
        .group_by(Consumption.user_id, Consumption.media_id, Consumption.media_type) \
        .subquery()

    # Filter consumption records above by the ones that match the selected status.
    consumption_w_status_subq = session.query(Consumption) \
        .join(consumption_subq, and_(Consumption.media_id == consumption_subq.c.media_id,
                         Consumption.media_type == consumption_subq.c.media_type,
                         Consumption.created == consumption_subq.c.max_created)) \
        .filter(Consumption.status == status) \
        .subquery()

    # Identify all media associated with consumption records above.
    results = session.query(media_class) \
        .join(consumption_w_status_subq, and_(media_class.id == consumption_w_status_subq.c.media_id))\
        .group_by(media_class)\
        .having(func.count(consumption_w_status_subq.c.user_id) > 1)\
        .all()

    return results


def get_friend_event_records(user_id, session):

    friend_subq = create_user_friends_subquery(user_id, session)

    final_results = []
    for media_type, media_class in MEDIAS.items():
        media_results = session.query(media_class, Consumption, User) \
            .join(Consumption, media_class.id == Consumption.media_id) \
            .join(User, Consumption.user_id == User.id) \
            .join(friend_subq, or_(User.id == friend_subq.c.requester_id,
                                   User.id == friend_subq.c.requested_id), isouter=True) \
            .filter(and_(Consumption.media_type == media_type,
                    or_(friend_subq.c.requested_id == user_id,
                        friend_subq.c.requester_id == user_id,
                        User.id == user_id))) \
            .all()

        final_results.append(media_results)

    return final_results


def create_user_friends_subquery(user_id, session):

    max_friend_link_subq = session.query(Friend.requester_id, Friend.requested_id,
                                         func.max(Friend.created).label("max_created")) \
        .group_by(Friend.requester_id, Friend.requested_id) \
        .subquery()

    friend_subq = session.query(Friend).filter(and_(or_(Friend.requested_id == user_id, Friend.requester_id == user_id),
                                                    Friend.status == FriendStatus.ACCEPTED.value)) \
        .join(max_friend_link_subq, and_(Friend.requester_id == max_friend_link_subq.c.requester_id,
                                         Friend.requested_id == max_friend_link_subq.c.requested_id,
                                         Friend.created == max_friend_link_subq.c.max_created)) \
        .subquery()

    return friend_subq
