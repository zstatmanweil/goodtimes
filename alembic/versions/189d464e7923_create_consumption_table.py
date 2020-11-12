"""create consumption table

Revision ID: 189d464e7923
Revises: 8a38baba3c1f
Create Date: 2020-11-11 18:01:52.832548

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '189d464e7923'
down_revision = '8a38baba3c1f'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'consumption',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id')),
        sa.Column('media_type', sa.String(50)),
        sa.Column('media_id', sa.Integer),
        sa.Column('status', sa.String(50)),
        sa.Column('created', sa.DateTime)
    )



def downgrade():
    op.drop_table('consumption')
