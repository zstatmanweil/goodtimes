from typing import List, Tuple

from sqlalchemy import and_, desc, func
from sqlalchemy.orm import session

from models.books import Book
from models.movies import Movie
from models.recommendation import Recommendation
from models.tv import TV
from models.consumption import Consumption
from models.user import User

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


def get_recommendation_records(user_id: int, media_type: str, session: session) -> List[Tuple]:
    """
    Get most recent records for all media associated with a user.
    :param user_id:
    :param media_type:
    :param session:
    :return: Returns a tuple of the Consumption object and Media object
    """
    media_class = MEDIAS.get(media_type)
    # Get most recent record for each item in recommendation table
    subq = session.query(Recommendation.recommended_user_id, Recommendation.media_id, Recommendation.media_type,
                         func.max(Recommendation.created).label("max_created")) \
        .group_by(Recommendation.recommended_user_id, Recommendation.media_id, Recommendation.media_type) \
        .subquery()

    # Get most recent consumption data for selected media for user
    results = session.query(Recommendation, media_class, User) \
        .filter_by(recommended_user_id=user_id, media_type=media_type) \
        .join(subq, and_(Recommendation.media_id == subq.c.media_id,
                         Recommendation.media_type == subq.c.media_type,
                         Recommendation.created == subq.c.max_created)) \
        .join(media_class, media_class.id == Recommendation.media_id) \
        .join(User, User.id == Recommendation.recommender_user_id) \
        .order_by(desc(Recommendation.created)) \
        .all()

    return results

