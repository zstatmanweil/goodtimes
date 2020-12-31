"""create friend table

Revision ID: 649ae8415d9c
Revises: 2d9ff28098ca
Create Date: 2020-12-28 15:50:03.422651

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '649ae8415d9c'
down_revision = '2d9ff28098ca'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'friend',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('requester_id', sa.Integer, sa.ForeignKey('user.id')),
        sa.Column('requested_id', sa.Integer, sa.ForeignKey('user.id')),
        sa.Column('status', sa.String(50)),
        sa.Column('created', sa.DateTime)
    )


def downgrade():
    op.drop_table('friend')
