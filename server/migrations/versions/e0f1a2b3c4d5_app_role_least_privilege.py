"""least-privilege app role (retention: security hardening)

Revision ID: e0f1a2b3c4d5
Revises: d9e0f1a2b3c4
Create Date: 2026-09-13

- สร้าง role `scamguard_app` แบบ NOLOGIN ให้สิทธิ์แค่ DML
  (SELECT/INSERT/UPDATE/DELETE) บนตารางปัจจุบัน + อนาคต (DEFAULT PRIVILEGES)
  ไม่มี DDL/CREATEDB — migration ยังรันด้วย owner (`scamguard`) เท่านั้น
- เปิดใช้งานจริง (ops, ไม่เก็บรหัสใน git):
    ALTER ROLE scamguard_app WITH LOGIN PASSWORD '<strong-password>';
  แล้วชี้ DATABASE_URL ของ app มาที่ user นี้
- PG15: PUBLIC ไม่มี CREATE บน schema public อยู่แล้ว จึงไม่ต้อง revoke เพิ่ม
"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = 'e0f1a2b3c4d5'
down_revision: Union[str, Sequence[str], None] = 'd9e0f1a2b3c4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

ROLE = 'scamguard_app'


def upgrade() -> None:
    conn = op.get_bind()
    dbname = conn.exec_driver_sql('SELECT current_database()').scalar()
    q = conn.dialect.identifier_preparer.quote

    op.execute(f'CREATE ROLE {ROLE} WITH NOLOGIN')
    conn.exec_driver_sql(f'GRANT CONNECT ON DATABASE {q(dbname)} TO {ROLE}')
    op.execute(f'GRANT USAGE ON SCHEMA public TO {ROLE}')
    op.execute(f'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {ROLE}')
    op.execute(f'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {ROLE}')
    # ตาราง/sequence ที่ migration ในอนาคตสร้าง (รันด้วย owner) ได้สิทธิ์อัตโนมัติ
    op.execute(f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
               f'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO {ROLE}')
    op.execute(f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
               f'GRANT USAGE, SELECT ON SEQUENCES TO {ROLE}')


def downgrade() -> None:
    op.execute(f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
               f'REVOKE ALL ON SEQUENCES FROM {ROLE}')
    op.execute(f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
               f'REVOKE ALL ON TABLES FROM {ROLE}')
    op.execute(f'REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM {ROLE}')
    op.execute(f'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM {ROLE}')
    op.execute(f'REVOKE USAGE ON SCHEMA public FROM {ROLE}')
    op.execute(f'DROP ROLE IF EXISTS {ROLE}')
