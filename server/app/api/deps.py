from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
from jose import JWTError

from app.core.database import get_db

from app.core.security import decode_access_token
from app.core.config import TH_TIMEZONE
from app.models.user import User
from app.models.admin import Admin
from app.models.admin_session import AdminSession

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    user_id: str = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is disabled")
    return user


async def get_current_admin(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> Admin:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate admin credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    admin_id: str = payload.get("sub")
    if admin_id is None or payload.get("role") != "admin":
        raise credentials_exception

    # Admin identity
    result = await db.execute(select(Admin).where(Admin.id == int(admin_id)))
    admin = result.scalars().first()
    if admin is None:
        raise credentials_exception
    if not admin.is_active:
        raise HTTPException(status_code=403, detail="Admin account is disabled")

    # Session check: access token ต้องผูกกับ session ที่ยัง valid (ไม่ถูก revoke/logout)
    session_id = payload.get("sid")
    if not session_id:
        raise credentials_exception
    session_result = await db.execute(select(AdminSession).where(AdminSession.id == session_id))
    session = session_result.scalars().first()
    if session is None or session.admin_id != int(admin_id):
        raise credentials_exception
    if session.revoked_at is not None:
        raise credentials_exception
    if session.expires_at is not None and session.expires_at <= datetime.now(TH_TIMEZONE):
        raise credentials_exception
    session.last_used_at = datetime.now(TH_TIMEZONE)

    return admin


async def require_super_admin(admin: Admin = Depends(get_current_admin)) -> Admin:
    """ทุก /admin/* ต้องเป็น Super Admin เท่านั้น (บังคับ is_superadmin)"""
    if not admin.is_superadmin:
        raise HTTPException(status_code=403, detail="Super Admin access required")
    return admin