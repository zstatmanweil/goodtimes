"""
This script is for creating a test user in the database.
"""
from datetime import datetime

from pyhocon import ConfigFactory
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

from models.user import User

config = ConfigFactory.parse_file('../config/config')

def add_user():
    engine = sa.create_engine(config.postgres_db, echo=True)
    Session = sessionmaker(bind=engine)

    first_user = User(username='zstat',
                email='zstatmanweil@gmail.com',
                first_name='zoe',
                last_name='statman-weil',
                created=datetime.utcnow())

    session = Session()
    session.add(first_user)
    session.commit()
    session.close()

if __name__ == '__main__':
    add_user()