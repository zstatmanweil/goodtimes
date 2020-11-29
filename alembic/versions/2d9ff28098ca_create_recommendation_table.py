"""create recommendation table

Revision ID: 2d9ff28098ca
Revises: 189d464e7923
Create Date: 2020-11-28 13:34:12.373549

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2d9ff28098ca'
down_revision = '189d464e7923'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('recommendation',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('recommender_user_id', sa.Integer, sa.ForeignKey("user.id")),
        sa.Column('recommended_user_id', sa.Integer, sa.ForeignKey("user.id")),
        sa.Column('media_type', sa.String(50)),
        sa.Column('media_id', sa.Integer),
        sa.Column('source_id', sa.String(50), index=True),
        sa.Column('status', sa.String(50)),
        sa.Column('created', sa.DateTime)
   )


def downgrade():
    op.drop_table('recommendation')
