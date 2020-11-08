"""create tv table

Revision ID: f2dcf0c69dad
Revises: d5b185188db9
Create Date: 2020-11-08 11:19:15.029151

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f2dcf0c69dad'
down_revision = 'd5b185188db9'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'tv',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source_id', sa.Integer),
        sa.Column('title', sa.String(200)),
        sa.Column('poster_url', sa.String(100)),
        sa.Column('first_air_date', sa.Date)
    )


def downgrade():
    op.drop_table('tv')
