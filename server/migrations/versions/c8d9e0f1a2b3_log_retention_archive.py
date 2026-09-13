"""log retention archive tables + audit trigger archive bypass (retention: 1 ปี)

Revision ID: c8d9e0f1a2b3
Revises: b7c8d9e0f1a2
Create Date: 2026-09-13

- ตาราง audit_log_archive / consent_logs_archive (schema เดียวกับตัวจริง + archived_at, ไม่มี FK/trigger)
- trigger trg_prevent_audit_log_modification ยังกัน UPDATE/DELETE เหมือนเดิม
  ยกเว้น DELETE ที่มากับ transaction ตั้ง SET LOCAL app.allow_audit_archive='on'
  (มีแค่ scripts/archive_old_logs.py ที่ใช้; transaction-scoped ไม่รั่วข้าม session)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'c8d9e0f1a2b3'
down_revision: Union[str, Sequence[str], None] = 'b7c8d9e0f1a2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'audit_log_archive',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('admin_id', sa.Integer(), nullable=True),
        sa.Column('action', sa.String(length=100), nullable=False),
        sa.Column('entity_type', sa.String(length=50), nullable=True),
        sa.Column('entity_id', sa.String(length=255), nullable=True),
        sa.Column('before_state', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('after_state', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('request_id', sa.String(length=100), nullable=True),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('archived_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_audit_log_archive_action'), 'audit_log_archive', ['action'], unique=False)
    op.create_index(op.f('ix_audit_log_archive_admin_id'), 'audit_log_archive', ['admin_id'], unique=False)
    op.create_index(op.f('ix_audit_log_archive_created_at'), 'audit_log_archive', ['created_at'], unique=False)
    op.create_index(op.f('ix_audit_log_archive_entity_type'), 'audit_log_archive', ['entity_type'], unique=False)

    op.create_table(
        'consent_logs_archive',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('system_consent', sa.Boolean(), nullable=False),
        sa.Column('research_consent', sa.Boolean(), nullable=False),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('archived_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_consent_logs_archive_user_id'), 'consent_logs_archive', ['user_id'], unique=False)

    # เปิดช่อง archive แบบ transaction-scoped (SET LOCAL) เฉพาะ DELETE
    op.execute("""
    CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
    RETURNS TRIGGER AS $$
    BEGIN
        IF TG_OP = 'DELETE'
           AND current_setting('app.allow_audit_archive', TRUE) = 'on' THEN
            RETURN OLD;
        END IF;
        RAISE EXCEPTION 'Audit logs are append-only. UPDATE and DELETE are not allowed.';
    END;
    $$ LANGUAGE plpgsql;
    """)


def downgrade() -> None:
    op.execute("""
    CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
    RETURNS TRIGGER AS $$
    BEGIN
        RAISE EXCEPTION 'Audit logs are append-only. UPDATE and DELETE are not allowed.';
    END;
    $$ LANGUAGE plpgsql;
    """)
    op.drop_index(op.f('ix_consent_logs_archive_user_id'), table_name='consent_logs_archive')
    op.drop_table('consent_logs_archive')
    op.drop_index(op.f('ix_audit_log_archive_entity_type'), table_name='audit_log_archive')
    op.drop_index(op.f('ix_audit_log_archive_created_at'), table_name='audit_log_archive')
    op.drop_index(op.f('ix_audit_log_archive_admin_id'), table_name='audit_log_archive')
    op.drop_index(op.f('ix_audit_log_archive_action'), table_name='audit_log_archive')
    op.drop_table('audit_log_archive')
