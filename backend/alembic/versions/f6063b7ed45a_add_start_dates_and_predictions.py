"""add_start_dates_and_predictions

Revision ID: f6063b7ed45a
Revises: 56c36e6a5fe1
Create Date: 2026-07-10 01:26:29.612280

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f6063b7ed45a'
down_revision: Union[str, None] = '56c36e6a5fe1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Drop award_completions table
    op.drop_table('award_completions', schema='scout')

    # 2. Create scout_awards table
    op.create_table(
        'scout_awards',
        sa.Column('id', sa.String(length=50), nullable=False),
        sa.Column('user_id', sa.String(length=50), nullable=False),
        sa.Column('award_id', sa.String(length=50), nullable=False),
        sa.Column('started_at', sa.Date(), nullable=False),
        sa.Column('completed_at', sa.Date(), nullable=True),
        sa.Column('certificate_url', sa.String(length=500), nullable=True),
        sa.Column('notes', sa.String(length=1000), nullable=True),
        sa.ForeignKeyConstraint(['award_id'], ['scout.awards.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['scout.users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'award_id', name='uq_user_award'),
        schema='scout'
    )

    # 3. Alter columns in scout_progress to sa.Date()
    op.alter_column('scout_progress', 'started_at',
               existing_type=sa.DateTime(),
               type_=sa.Date(),
               existing_nullable=True,
               schema='scout')
    op.alter_column('scout_progress', 'completed_at',
               existing_type=sa.DateTime(),
               type_=sa.Date(),
               existing_nullable=True,
               schema='scout')


def downgrade() -> None:
    op.alter_column('scout_progress', 'completed_at',
               existing_type=sa.Date(),
               type_=sa.DateTime(),
               existing_nullable=True,
               schema='scout')
    op.alter_column('scout_progress', 'started_at',
               existing_type=sa.Date(),
               type_=sa.DateTime(),
               existing_nullable=True,
               schema='scout')
    op.drop_table('scout_awards', schema='scout')
    
    op.create_table(
        'award_completions',
        sa.Column('id', sa.String(length=50), nullable=False),
        sa.Column('user_id', sa.String(length=50), nullable=False),
        sa.Column('award_id', sa.String(length=50), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=False),
        sa.Column('certificate_url', sa.String(length=500), nullable=True),
        sa.Column('notes', sa.String(length=1000), nullable=True),
        sa.ForeignKeyConstraint(['award_id'], ['scout.awards.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['scout.users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'award_id', name='uq_user_award'),
        schema='scout'
    )

