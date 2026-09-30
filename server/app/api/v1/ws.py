from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_db
from app.core.websocket import manager
from app.services.admin_access_policy import AdminAccessError, resolve_admin_access

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
    if not token:
        return False
    try:
        await resolve_admin_access(token, db, require_superadmin=True)
    except AdminAccessError:
        return False
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
