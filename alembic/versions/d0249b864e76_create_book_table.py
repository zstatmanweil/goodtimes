"""create book table

Revision ID: d0249b864e76
Revises: 
Create Date: 2020-11-08 10:08:48.463243

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd0249b864e76'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'book',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('source', sa.String(50)),
        sa.Column('source_id', sa.String(50), index=True),
        sa.Column('title', sa.String(200)),
        sa.Column('author_name', sa.String(100)),
        sa.Column('cover_url', sa.String(250)),
        sa.Column('publish_year', sa.Integer)
    )


def downgrade():
    op.drop_table('book')
