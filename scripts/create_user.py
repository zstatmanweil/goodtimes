"""
This script is for creating a test user in the database.
"""
import pathlib
import sys
from datetime import datetime

from pyhocon import ConfigFactory
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

sys.path.append(pathlib.Path(__file__).parent.parent.absolute().as_posix())
from models.user import User

config = ConfigFactory.parse_file('config/config')


def add_users():
    engine = sa.create_engine(config.postgres_db, echo=True)
    Session = sessionmaker(bind=engine)


    second_user = User(
        auth0_sub='123',
        email='astrick@gmail.com',
        first_name='aaron',
        last_name='strick',
        full_name='aaron strick')

    # third_user = User(
    #     auth0_sub='123',
    #     email='jakejhanft@gmail.com',
    #     first_name='jake',
    #     last_name='hanft',
    #     full_name='jake hanft'
    # )

    fourth_user = User(
        auth0_sub='123',
        email='lucyrosetaylor@gmail.com',
        first_name='lucy rose',
        last_name='taylor',
        full_name='lucy rose taylor'
    )

    session = Session()
    session.add(second_user)
    # session.add(third_user)
    session.add(fourth_user)
    print("testing")
    session.commit()
    session.close()


if __name__ == '__main__':
    add_users()