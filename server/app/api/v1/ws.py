from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.websocket import manager
from app.core.security import decode_access_token
from app.models.user import User

router = APIRouter()

@router.websocket("/admin/dashboard")
async def websocket_admin_dashboard(websocket: WebSocket, token: str):
    # Authenticate via query param
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "admin":
        await websocket.close(code=1008)
        return

    await manager.connect(websocket)
    try:
        while True:
            # We just keep connection alive and wait for messages (e.g. ping)
            # The server will broadcast events to the client independently
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
