"""Add append only trigger to audit log

Revision ID: e3844dc4110e
Revises: 54e8b8cb0526
Create Date: 2026-08-09 16:39:45.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'e3844dc4110e'
down_revision = '54e8b8cb0526'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Create function
    op.execute("""
    CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
    RETURNS TRIGGER AS $$
    BEGIN
        RAISE EXCEPTION 'Audit logs are append-only. UPDATE and DELETE are not allowed.';
    END;
    $$ LANGUAGE plpgsql;
    """)

    # 2. Create trigger
    op.execute("""
    CREATE TRIGGER trg_prevent_audit_log_modification
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();
    """)


def downgrade() -> None:
    # 1. Drop trigger
    op.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_log_modification ON audit_log")
    
    # 2. Drop function
    op.execute("DROP FUNCTION IF EXISTS prevent_audit_log_modification()")
