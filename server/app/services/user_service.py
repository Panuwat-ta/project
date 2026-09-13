from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update

from app.models.user import User
from app.models.consent import ConsentLog
from app.core.security import verify_password


async def delete_account(db: AsyncSession, user: User, password: str) -> None:
    """ลบบัญชีผู้ใช้ (soft-delete):
    1. ยืนยันรหัสผ่านซ้ำ
    2. anonymize consent (ล้าง ip/user_agent) — trigger ลบ user ไม่ยิงเพราะไม่ใช่ hard delete
    3. is_active=False (login/refresh/get_current_user บล็อกทันทีผ่าน is_active check)
    4. scan/report ของ user อยู่ต่อ (FK SET NULL ตัด link ให้เมื่อ hard delete ภายหลัง;
       ไฟล์รูปโดน purge ตามรอบ 90 วัน)
    """
    if not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password",
        )
    await db.execute(
        update(ConsentLog)
        .where(ConsentLog.user_id == user.id)
        .values(ip_address=None, user_agent=None)
    )
    user.is_active = False
    await db.commit()
