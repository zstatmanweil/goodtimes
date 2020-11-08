"""create user table

Revision ID: 8a38baba3c1f
Revises: f2dcf0c69dad
Create Date: 2020-11-08 11:24:56.844104

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8a38baba3c1f'
down_revision = 'f2dcf0c69dad'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'user',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('username', sa.String(100)),
        sa.Column('email', sa.String(100)),
        sa.Column('first_name', sa.String(100)),
        sa.Column('last_name', sa.String(100)),
        sa.Column('created', sa.DateTime)
    )


def downgrade():
    op.drop_table('user')
