"""
This script is for creating a test user in the database.
"""
from datetime import datetime

from pyhocon import ConfigFactory
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.user import User

config = ConfigFactory.parse_file('../config/config')


def add_users():
    engine = sa.create_engine(config.postgres_db, echo=True)
    Session = sessionmaker(bind=engine)

    first_user = User(username='zstat',
                email='zstatmanweil@gmail.com',
                first_name='zoe',
                last_name='statman-weil',
                created=datetime.utcnow())

    second_user = User(username='strickinato',
                      email='astrick@gmail.com',
                      first_name='aaron',
                      last_name='strick',
                      created=datetime.utcnow())

    third_user = User(username='jakey',
                      email='jakejhanft@gmail.com',
                      first_name='jake',
                      last_name='hanft',
                      created=datetime.utcnow())

    fourth_user = User(username='lulu',
                       email='lucyrosetaylor@gmail.com',
                       first_name='lucy rose',
                       last_name='taylor',
                       created=datetime.utcnow())

    session = Session()
    # session.add(first_user)
    # session.add(second_user)
    session.add(third_user)
    session.add(fourth_user)
    session.commit()
    session.close()

if __name__ == '__main__':
    add_users()