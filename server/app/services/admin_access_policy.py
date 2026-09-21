from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.config import TH_TIMEZONE
from app.core.security import decode_access_token
from app.models.admin import Admin
from app.models.admin_session import AdminSession


class AdminAccessError(Exception):
    """Base error for transport-neutral admin access validation."""


class InvalidAdminCredentials(AdminAccessError):
    pass


class AdminAccountDisabled(AdminAccessError):
    pass


class SuperAdminRequired(AdminAccessError):
    pass


async def resolve_admin_access(
    token: str,
    db: AsyncSession,
    *,
    require_superadmin: bool = False,
) -> tuple[Admin, AdminSession]:
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "admin":
        raise InvalidAdminCredentials

    raw_admin_id = payload.get("sub")
    session_id = payload.get("sid")
    if raw_admin_id is None or not session_id:
        raise InvalidAdminCredentials

    try:
        admin_id = int(raw_admin_id)
    except (TypeError, ValueError) as exc:
        raise InvalidAdminCredentials from exc

    admin_result = await db.execute(select(Admin).where(Admin.id == admin_id))
    admin = admin_result.scalars().first()
    if admin is None:
        raise InvalidAdminCredentials
    if not admin.is_active:
        raise AdminAccountDisabled
    if require_superadmin and not admin.is_superadmin:
        raise SuperAdminRequired

    session_result = await db.execute(select(AdminSession).where(AdminSession.id == session_id))
    session = session_result.scalars().first()
    if session is None or session.admin_id != admin_id or session.revoked_at is not None:
        raise InvalidAdminCredentials

    now = datetime.now(TH_TIMEZONE)
    if session.expires_at is not None and session.expires_at <= now:
        raise InvalidAdminCredentials

    session.last_used_at = now
    return admin, session
