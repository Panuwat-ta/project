"""design review fixes: CHECK constraints, FK indexes, uniform ON DELETE SET NULL

Revision ID: d4e5f6a7b8c9
Revises: efdfc08f2155
Create Date: 2026-09-13

- users.role: CHECK (user, researcher) — admin แยกตาราง admins
- scans.status / scores / progress: CHECK
- scam_reports.category / status: CHECK + index FK (user_id, scan_id, moderated_by)
- consent_logs.user_id: CASCADE -> SET NULL + nullable (เก็บหลักฐาน PDPA)
- model_versions.created_by / export_jobs.admin_id: NO ACTION -> SET NULL + index
- export_jobs.status / model_versions.status: CHECK
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, Sequence[str], None] = 'efdfc08f2155'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


SCAN_STATUSES = (
    "'pending', 'uploading', 'queued', 'processing_source', "
    "'processing_visual', 'processing_text', 'completed', 'failed'"
)
REPORT_CATEGORIES = (
    "'romance_scam', 'online_shopping', 'fake_slip', 'investment', "
    "'identity_theft', 'ai_deepfake', 'other'"
)


def upgrade() -> None:
    # --- data migration: ค่า legacy ก่อนยุค DOC-08 ---
    # 'fake_image' ไม่มีใน canonical categories แล้ว -> 'other' (3 rows, ไม่มีใน API/schema ปัจจุบัน)
    op.execute("UPDATE scam_reports SET category = 'other' WHERE category = 'fake_image'")

    # --- CHECK constraints ---
    op.create_check_constraint('ck_users_role', 'users', "role IN ('user', 'researcher')")
    op.create_check_constraint('ck_scans_status', 'scans', f"status IN ({SCAN_STATUSES})")
    op.create_check_constraint('ck_scans_text_score', 'scans', 'text_score BETWEEN 0 AND 100')
    op.create_check_constraint('ck_scans_visual_score', 'scans', 'visual_score BETWEEN 0 AND 100')
    op.create_check_constraint('ck_scans_source_score', 'scans', 'source_score BETWEEN 0 AND 100')
    op.create_check_constraint('ck_scans_total_risk_score', 'scans', 'total_risk_score BETWEEN 0 AND 100')
    op.create_check_constraint('ck_scans_progress', 'scans', 'progress BETWEEN 0 AND 100')
    op.create_check_constraint('ck_scam_reports_category', 'scam_reports', f'category IN ({REPORT_CATEGORIES})')
    op.create_check_constraint(
        'ck_scam_reports_status', 'scam_reports',
        "status IN ('pending', 'reviewing', 'approved', 'rejected')",
    )
    op.create_check_constraint(
        'ck_model_versions_status', 'model_versions',
        "status IN ('pending', 'active', 'inactive', 'failed')",
    )
    op.create_check_constraint(
        'ck_export_jobs_status', 'export_jobs',
        "status IN ('queued', 'running', 'succeeded', 'failed', 'canceled', 'expired')",
    )

    # --- nullable ก่อนเปลี่ยน FK เป็น SET NULL ---
    op.alter_column('consent_logs', 'user_id', existing_type=sa.Integer(), nullable=True)
    op.alter_column('export_jobs', 'admin_id', existing_type=sa.Integer(), nullable=True)

    # --- FK: uniform ON DELETE SET NULL ---
    op.drop_constraint(op.f('consent_logs_user_id_fkey'), 'consent_logs', type_='foreignkey')
    op.create_foreign_key(None, 'consent_logs', 'users', ['user_id'], ['id'], ondelete='SET NULL')
    op.drop_constraint(op.f('scam_reports_moderated_by_fkey'), 'scam_reports', type_='foreignkey')
    op.create_foreign_key(None, 'scam_reports', 'admins', ['moderated_by'], ['id'], ondelete='SET NULL')
    op.drop_constraint(op.f('model_versions_created_by_fkey'), 'model_versions', type_='foreignkey')
    op.create_foreign_key(None, 'model_versions', 'admins', ['created_by'], ['id'], ondelete='SET NULL')
    op.drop_constraint(op.f('export_jobs_admin_id_fkey'), 'export_jobs', type_='foreignkey')
    op.create_foreign_key(None, 'export_jobs', 'admins', ['admin_id'], ['id'], ondelete='SET NULL')

    # --- index บน FK ที่ขาด ---
    op.create_index(op.f('ix_scam_reports_user_id'), 'scam_reports', ['user_id'], unique=False)
    op.create_index(op.f('ix_scam_reports_scan_id'), 'scam_reports', ['scan_id'], unique=False)
    op.create_index(op.f('ix_scam_reports_moderated_by'), 'scam_reports', ['moderated_by'], unique=False)
    op.create_index(op.f('ix_consent_logs_user_id'), 'consent_logs', ['user_id'], unique=False)
    op.create_index(op.f('ix_model_versions_created_by'), 'model_versions', ['created_by'], unique=False)
    op.create_index(op.f('ix_export_jobs_admin_id'), 'export_jobs', ['admin_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_export_jobs_admin_id'), table_name='export_jobs')
    op.drop_index(op.f('ix_model_versions_created_by'), table_name='model_versions')
    op.drop_index(op.f('ix_consent_logs_user_id'), table_name='consent_logs')
    op.drop_index(op.f('ix_scam_reports_moderated_by'), table_name='scam_reports')
    op.drop_index(op.f('ix_scam_reports_scan_id'), table_name='scam_reports')
    op.drop_index(op.f('ix_scam_reports_user_id'), table_name='scam_reports')

    op.drop_constraint(op.f('export_jobs_admin_id_fkey'), 'export_jobs', type_='foreignkey')
    op.create_foreign_key(op.f('export_jobs_admin_id_fkey'), 'export_jobs', 'admins', ['admin_id'], ['id'])
    op.drop_constraint(op.f('model_versions_created_by_fkey'), 'model_versions', type_='foreignkey')
    op.create_foreign_key(op.f('model_versions_created_by_fkey'), 'model_versions', 'admins', ['created_by'], ['id'])
    op.drop_constraint(op.f('scam_reports_moderated_by_fkey'), 'scam_reports', type_='foreignkey')
    op.create_foreign_key(op.f('scam_reports_moderated_by_fkey'), 'scam_reports', 'admins', ['moderated_by'], ['id'])
    op.drop_constraint(op.f('consent_logs_user_id_fkey'), 'consent_logs', type_='foreignkey')
    op.create_foreign_key(op.f('consent_logs_user_id_fkey'), 'consent_logs', 'users', ['user_id'], ['id'], ondelete='CASCADE')

    op.alter_column('export_jobs', 'admin_id', existing_type=sa.Integer(), nullable=False)
    op.alter_column('consent_logs', 'user_id', existing_type=sa.Integer(), nullable=False)

    op.drop_constraint('ck_export_jobs_status', 'export_jobs', type_='check')
    op.drop_constraint('ck_model_versions_status', 'model_versions', type_='check')
    op.drop_constraint('ck_scam_reports_status', 'scam_reports', type_='check')
    op.drop_constraint('ck_scam_reports_category', 'scam_reports', type_='check')
    op.drop_constraint('ck_scans_progress', 'scans', type_='check')
    op.drop_constraint('ck_scans_total_risk_score', 'scans', type_='check')
    op.drop_constraint('ck_scans_source_score', 'scans', type_='check')
    op.drop_constraint('ck_scans_visual_score', 'scans', type_='check')
    op.drop_constraint('ck_scans_text_score', 'scans', type_='check')
    op.drop_constraint('ck_scans_status', 'scans', type_='check')
    op.drop_constraint('ck_users_role', 'users', type_='check')
