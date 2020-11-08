"""create movie table

Revision ID: d5b185188db9
Revises: d0249b864e76
Create Date: 2020-11-08 10:59:37.034476

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd5b185188db9'
down_revision = 'd0249b864e76'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'movie',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source_id', sa.Integer),
        sa.Column('title', sa.String(200)),
        sa.Column('poster_url', sa.String(100)),
        sa.Column('release_date', sa.Date)
    )


def downgrade():
    op.drop_table('movie')
