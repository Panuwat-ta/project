from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.api.v1 import ws as ws_api
from app.core.config import TH_TIMEZONE
from app.core.database import get_db
from app.core.security import create_access_token


class _Result:
    def __init__(self, value):
        self.value = value

    def scalars(self):
        return self

    def first(self):
        return self.value


class _Db:
    def __init__(self, admin, session):
        self.admin = admin
        self.session = session
        self.commits = 0
        self._reads = 0

    async def execute(self, _stmt):
        self._reads += 1
        return _Result(self.admin if self._reads == 1 else self.session)

    async def commit(self):
        self.commits += 1


def _make_context(*, revoked=False, superadmin=True, expired=False):
    admin = SimpleNamespace(id=1, is_active=True, is_superadmin=superadmin)
    session = SimpleNamespace(
        id="session-1",
        admin_id=1,
        revoked_at=datetime.now(TH_TIMEZONE) if revoked else None,
        expires_at=datetime.now(TH_TIMEZONE) + (timedelta(minutes=-1) if expired else timedelta(minutes=10)),
        last_used_at=None,
    )
    return admin, session


def _client(admin, session):
    app = FastAPI()
    app.include_router(ws_api.router, prefix="/ws")
    db = _Db(admin, session)

    async def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    return TestClient(app), db


def _token():
    return create_access_token(
        data={"sub": "1", "role": "admin"},
        sid="session-1",
    )


def test_websocket_accepts_active_superadmin_session():
    admin, session = _make_context()
    client, db = _client(admin, session)

    with client.websocket_connect(
        "/ws/admin/dashboard",
        subprotocols=[ws_api.WS_PROTOCOL, _token()],
    ) as socket:
        assert socket.accepted_subprotocol == ws_api.WS_PROTOCOL
        socket.send_text("ping")

    assert db.commits == 1
    assert session.last_used_at is not None


def test_websocket_rejects_revoked_session():
    admin, session = _make_context(revoked=True)
    client, db = _client(admin, session)

    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(
            "/ws/admin/dashboard",
            subprotocols=[ws_api.WS_PROTOCOL, _token()],
        ):
            pass

    assert exc.value.code == 1008
    assert db.commits == 0


def test_websocket_rejects_legacy_query_token():
    admin, session = _make_context()
    client, db = _client(admin, session)

    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(
            f"/ws/admin/dashboard?token={_token()}",
        ):
            pass

    assert exc.value.code == 1008
    assert db.commits == 0


def test_websocket_rejects_expired_session():
    admin, session = _make_context(expired=True)
    client, db = _client(admin, session)

    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(
            "/ws/admin/dashboard",
            subprotocols=[ws_api.WS_PROTOCOL, _token()],
        ):
            pass

    assert exc.value.code == 1008
    assert db.commits == 0


def test_websocket_rejects_non_superadmin():
    admin, session = _make_context(superadmin=False)
    client, db = _client(admin, session)

    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(
            "/ws/admin/dashboard",
            subprotocols=[ws_api.WS_PROTOCOL, _token()],
        ):
            pass

    assert exc.value.code == 1008
    assert db.commits == 0
