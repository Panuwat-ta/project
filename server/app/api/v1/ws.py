from datetime import datetime

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.api.deps import get_db
from app.core.config import TH_TIMEZONE
from app.core.security import decode_access_token
from app.core.websocket import manager
from app.models.admin import Admin
from app.models.admin_session import AdminSession

router = APIRouter()
WS_PROTOCOL = "scamguard-admin"


def _extract_protocol_token(websocket: WebSocket) -> str | None:
    offered = websocket.headers.get("sec-websocket-protocol", "")
    protocols = [item.strip() for item in offered.split(",") if item.strip()]
    if len(protocols) != 2 or protocols[0] != WS_PROTOCOL:
        return None
    return protocols[1]


async def _authenticate_admin_websocket(websocket: WebSocket, db: AsyncSession) -> bool:
    token = _extract_protocol_token(websocket)
    payload = decode_access_token(token) if token else None
    if not payload or payload.get("role") != "admin":
        return False

    admin_id = payload.get("sub")
    session_id = payload.get("sid")
    if admin_id is None or not session_id:
        return False

    try:
        admin_id = int(admin_id)
    except (TypeError, ValueError):
        return False

    admin_result = await db.execute(select(Admin).where(Admin.id == admin_id))
    admin = admin_result.scalars().first()
    if not admin or not admin.is_active or not admin.is_superadmin:
        return False

    session_result = await db.execute(select(AdminSession).where(AdminSession.id == session_id))
    session = session_result.scalars().first()
    if not session or session.admin_id != admin_id or session.revoked_at is not None:
        return False
    if session.expires_at is not None and session.expires_at <= datetime.now(TH_TIMEZONE):
        return False

    session.last_used_at = datetime.now(TH_TIMEZONE)
    await db.commit()
    return True


@router.websocket("/admin/dashboard")
async def websocket_admin_dashboard(
    websocket: WebSocket,
    db: AsyncSession = Depends(get_db),
):
    if not await _authenticate_admin_websocket(websocket, db):
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, subprotocol=WS_PROTOCOL)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
