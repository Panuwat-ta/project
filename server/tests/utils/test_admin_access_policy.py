from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.api.deps import get_current_admin
from app.core.config import TH_TIMEZONE
from app.core.security import create_access_token
from app.services.admin_access_policy import (
    AdminAccountDisabled,
    InvalidAdminCredentials,
    SuperAdminRequired,
    resolve_admin_access,
)


class _Result:
    def __init__(self, value):
        self.value = value

    def scalars(self):
        return self

    def first(self):
        return self.value


class _Db:
    def __init__(self, admin, session):
        self.values = iter((admin, session))
        self.commit_count = 0

    async def execute(self, _stmt):
        return _Result(next(self.values))

    async def commit(self):
        self.commit_count += 1


def _context(*, active=True, superadmin=True, revoked=False, expired=False):
    admin = SimpleNamespace(id=1, is_active=active, is_superadmin=superadmin)
    session = SimpleNamespace(
        id="session-1",
        admin_id=1,
        revoked_at=datetime.now(TH_TIMEZONE) if revoked else None,
        expires_at=datetime.now(TH_TIMEZONE)
        + (timedelta(minutes=-1) if expired else timedelta(minutes=10)),
        last_used_at=None,
    )
    return admin, session


def _token(*, sub="1", role="admin", sid="session-1"):
    return create_access_token(data={"sub": sub, "role": role}, sid=sid)


@pytest.mark.asyncio
async def test_resolve_admin_access_accepts_active_session():
    admin, session = _context()
    db = _Db(admin, session)
    resolved_admin, resolved_session = await resolve_admin_access(
        _token(), db, require_superadmin=True
    )

    assert resolved_admin is admin
    assert resolved_session is session
    assert session.last_used_at is not None
    assert db.commit_count == 1


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("token", "admin", "session", "error"),
    [
        (_token(sub="not-an-int"), *_context(), InvalidAdminCredentials),
        (_token(role="user"), *_context(), InvalidAdminCredentials),
        (_token(), *_context(active=False), AdminAccountDisabled),
        (_token(), *_context(revoked=True), InvalidAdminCredentials),
        (_token(), *_context(expired=True), InvalidAdminCredentials),
        (_token(), *_context(superadmin=False), SuperAdminRequired),
    ],
)
async def test_resolve_admin_access_rejects_invalid_policy_states(
    token, admin, session, error
):
    with pytest.raises(error):
        await resolve_admin_access(
            token,
            _Db(admin, session),
            require_superadmin=True,
        )


@pytest.mark.asyncio
async def test_http_dependency_maps_malformed_subject_to_401():
    admin, session = _context()
    with pytest.raises(HTTPException) as exc:
        await get_current_admin(_token(sub="not-an-int"), _Db(admin, session))

    assert exc.value.status_code == 401
    assert exc.value.detail == "Could not validate admin credentials"


@pytest.mark.asyncio
async def test_http_dependency_maps_disabled_admin_to_403():
    admin, session = _context(active=False)
    with pytest.raises(HTTPException) as exc:
        await get_current_admin(_token(), _Db(admin, session))

    assert exc.value.status_code == 403
    assert exc.value.detail == "Admin account is disabled"
