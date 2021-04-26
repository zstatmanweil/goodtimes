"""
This script is for creating a test user in the database.
"""
import pathlib
import sys

from pyhocon import ConfigFactory
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

sys.path.append(pathlib.Path(__file__).parent.parent.absolute().as_posix())
from models.user import User
from config import DATABASE_URL

def add_users():
    engine = sa.create_engine(DATABASE_URL, echo=True)
    Session = sessionmaker(bind=engine)


    second_user = User(
        auth0_sub='123',
        email='astrick@gmail.com',
        first_name='aaron',
        last_name='strick',
        full_name='aaron strick')

    third_user = User(
        auth0_sub='123',
        email='jakejhanft@gmail.com',
        first_name='jake',
        last_name='hanft',
        full_name='jake hanft'
    )

    fourth_user = User(
        auth0_sub='123',
        email='lucyrosetaylor@gmail.com',
        first_name='lucy rose',
        last_name='taylor',
        full_name='lucy rose taylor'
    )

    fifth_user = User(
        auth0_sub='222',
        email='cutiepie2@gmail.com',
        first_name='pilot',
        last_name='taylor-strick',
        full_name='pilot taylor-strick'
    )

    session = Session()
    # session.add(second_user)
    # session.add(third_user)
    # session.add(fourth_user)
    session.add(fifth_user)
    print("testing")
    session.commit()
    session.close()


if __name__ == '__main__':
    add_users()