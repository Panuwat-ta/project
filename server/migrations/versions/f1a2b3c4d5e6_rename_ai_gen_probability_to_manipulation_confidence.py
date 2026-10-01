"""rename ai_gen_probability -> manipulation_confidence (semantic correction)

Revision ID: f1a2b3c4d5e6
Revises: e0f1a2b3c4d5
Create Date: 2026-09-30

- ค่าเดิมมาจาก `prob_map.max()` ซึ่งเป็นค่าสูงสุดระดับพิกเซล ไม่ใช่ความน่าจะเป็น
  ระดับภาพ บนภาพ 12 MP ค่านี้จึงสูงเกือบ 1.0 เกือบทุกภาพ (วัดได้ ~0.99 บนภาพ
  ถ่ายจริง) ทำให้ข้อความ XAI ขัดแย้งกับตัวเอง และสื่อว่าเป็นภาพสังเคราะห์ด้วย AI
  ทั้งที่โมเดลไม่มีความสามารถวัดการสังเคราะห์ด้วย AI เลย (seg เป็น 2 คลาส
  authentic/forged และ det head เป็น binary เดียวกัน)
- ตั้งแต่ 2026-09-30 ค่านี้มาจาก Det Head ซึ่งเป็นความม่ันใจระดับภาพว่าภาพถูก
  ตัดต่อหรือดัดแปลง จึงเปลี่ยนชื่อคอลัมน์และชื่อ field ให้ตรงความหมาย
- ค่าของแถวเดิม 24 รายการเป็นค่าแบบเก่าที่ไม่มีความหมายภายใต้นิยามใหม่ จึง
  ตั้งเป็น NULL แทนการคงค่าไว้ เพื่อไม่ให้แสดงตัวเลขที่ทำให้เข้าใจผิด
  (คอลัมน์เปลี่ยนเป็น nullable)
"""
from typing import Sequence, Union

from alembic import op
from sqlalchemy import Float, text

revision: str = 'f1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'e0f1a2b3c4d5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

OLD = 'ai_gen_probability'
NEW = 'manipulation_confidence'


TABLE = 'scans'


def upgrade() -> None:
    # ต้องระบุ table_name เสมอ ไม่เช่นนั้น Alembic จะตีความชื่อเก่าเป็นชื่อตาราง
    op.alter_column(
        TABLE, OLD, new_column_name=NEW, existing_type=Float(), nullable=True
    )
    # ค่าเดิมเป็น max-prob ระดับพิกเซล ซึ่งไม่ใช่ความม่ันใจระดับภาพ
    op.execute(f'UPDATE {TABLE} SET {NEW} = NULL WHERE {NEW} IS NOT NULL')


def downgrade() -> None:
    # คืนชื่อคอลัมน์เดิม แต่ต้อง DROP NOT NULL ก่อน เพราะค่าของแถวเดิมเป็น NULL
    # และคอลัมน์เดิมเป็น NOT NULL (ค่า 0.0 แทนความหมายเดิมของ max-prob)
    op.alter_column(TABLE, NEW, existing_type=Float(), nullable=True)
    op.alter_column(
        TABLE, NEW, new_column_name=OLD, existing_type=Float(), nullable=True
    )
    op.execute(f'UPDATE {TABLE} SET {OLD} = 0.0 WHERE {OLD} IS NULL')