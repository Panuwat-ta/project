"""anonymize consent PII on user delete (decision ข้อ 4)

Revision ID: b7c8d9e0f1a2
Revises: d4e5f6a7b8c9
Create Date: 2026-09-13

- ยังไม่มี delete-account endpoint การลบ user เกิดนอก app ได้ทุกทาง
  trigger จึงเป็นจุดเดียวที่รับประกัน anonymization เสมอ
- วันใดมี endpoint ลบ account ให้ย้าย logic นี้ไปไว้ใน service + คง trigger
  เป็น safety net หรือถอดออกแล้วแต่ทีม
- FK consent_logs.user_id (SET NULL) ทำงานร่วมกับ trigger ได้ ไม่ขัดกัน:
  trigger ล้าง ip/user_agent, FK ตัด link
"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = 'b7c8d9e0f1a2'
down_revision: Union[str, Sequence[str], None] = 'd4e5f6a7b8c9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create function
    op.execute("""
    CREATE OR REPLACE FUNCTION anonymize_consent_on_user_delete()
    RETURNS TRIGGER AS $$
    BEGIN
        UPDATE consent_logs
        SET ip_address = NULL,
            user_agent = NULL
        WHERE user_id = OLD.id;
        RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;
    """)

    # 2. Create trigger
    op.execute("""
    CREATE TRIGGER trg_anonymize_consent_on_user_delete
    BEFORE DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION anonymize_consent_on_user_delete();
    """)


def downgrade() -> None:
    # 1. Drop trigger
    op.execute("DROP TRIGGER IF EXISTS trg_anonymize_consent_on_user_delete ON users")

    # 2. Drop function
    op.execute("DROP FUNCTION IF EXISTS anonymize_consent_on_user_delete()")
