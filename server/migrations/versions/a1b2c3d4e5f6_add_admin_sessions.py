"""Add admin_sessions table (token revocation / rotation)

Revision ID: a1b2c3d4e5f6
Revises: 62cb9477cf84
Create Date: 2026-08-09 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '62cb9477cf84'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('admin_sessions',
    sa.Column('id', sa.String(length=64), nullable=False),
    sa.Column('admin_id', sa.Integer(), nullable=False),
    sa.Column('refresh_hash', sa.String(length=64), nullable=False),
    sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('replaced_by', sa.String(length=64), nullable=True),
    sa.Column('user_agent', sa.String(length=255), nullable=True),
    sa.Column('ip_address', sa.String(length=64), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
    sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
    sa.PrimaryKeyConstraint('id'),
    sa.ForeignKeyConstraint(['admin_id'], ['admins.id'], ondelete='CASCADE'),
    )
    op.create_index(op.f('ix_admin_sessions_admin_id'), 'admin_sessions', ['admin_id'], unique=False)
    op.create_index(op.f('ix_admin_sessions_refresh_hash'), 'admin_sessions', ['refresh_hash'], unique=True)
    op.create_index(op.f('ix_admin_sessions_revoked_at'), 'admin_sessions', ['revoked_at'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_admin_sessions_revoked_at'), table_name='admin_sessions')
    op.drop_index(op.f('ix_admin_sessions_refresh_hash'), table_name='admin_sessions')
    op.drop_index(op.f('ix_admin_sessions_admin_id'), table_name='admin_sessions')
    op.drop_table('admin_sessions')