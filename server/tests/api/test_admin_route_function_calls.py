from datetime import datetime, timedelta
import inspect
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import BackgroundTasks

import app.api.v1.admin as admin_router
from app.core.config import TH_TIMEZONE
from app.core.security import create_access_token


def _admin():
    return SimpleNamespace(
        id=1, email="admin@example.test", full_name="Admin",
        is_active=True, is_superadmin=True, hashed_password="hash",
    )


def _route(fn):
    return inspect.unwrap(fn)


def _request(token=None):
    headers = {"user-agent": "pytest"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return SimpleNamespace(client=SimpleNamespace(host="127.0.0.1"), headers=headers)


def _scalar_result(*, first=None, one=None, items=None):
    result = MagicMock()
    result.scalars.return_value.first.return_value = first
    result.scalar_one_or_none.return_value = one
    result.scalars.return_value.all.return_value = items or []
    return result


@pytest.mark.asyncio
async def test_profile_get_and_update_functions(monkeypatch):
    admin = _admin()
    db = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    profile = await _route(admin_router.get_me)(_request(), current_admin=admin)
    assert profile["email"] == admin.email
    assert profile["is_superadmin"] is True

    body = SimpleNamespace(full_name="Renamed Admin", current_password=None, new_password=None)
    updated = await _route(admin_router.update_me)(_request(), body, db=db, current_admin=admin)
    assert updated["full_name"] == "Renamed Admin"
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(admin)


@pytest.mark.asyncio
async def test_profile_password_update_hashes_after_verification(monkeypatch):
    admin = _admin()
    db = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    monkeypatch.setattr(admin_router, "verify_password", lambda plain, hashed: plain == "old-pass")
    monkeypatch.setattr(admin_router, "hash_password", lambda value: f"hashed:{value}")

    body = SimpleNamespace(full_name=None, current_password="old-pass", new_password="new-pass-123")
    await _route(admin_router.update_me)(_request(), body, db=db, current_admin=admin)
    assert admin.hashed_password == "hashed:new-pass-123"


@pytest.mark.asyncio
async def test_session_list_marks_current_and_revoke_delegates(monkeypatch):
    now = datetime.now(TH_TIMEZONE)
    current_sid = "sid-current"
    token = create_access_token({"sub": "1", "role": "admin"}, sid=current_sid)
    sessions = [
        SimpleNamespace(id=current_sid, user_agent="pytest", ip_address="127.0.0.1", created_at=now, last_used_at=now, expires_at=now + timedelta(hours=1), revoked_at=None),
        SimpleNamespace(id="sid-old", user_agent="other", ip_address="127.0.0.2", created_at=now, last_used_at=now, expires_at=now + timedelta(hours=1), revoked_at=now),
    ]
    db = MagicMock()
    db.execute = AsyncMock(return_value=_scalar_result(items=sessions))

    result = await _route(admin_router.get_sessions)(_request(token), db=db, current_admin=_admin())
    assert result["total"] == 2
    assert result["items"][0]["is_current"] is True
    assert result["items"][1]["is_current"] is False

    revoked = SimpleNamespace(id="sid-old", revoked_at=now)
    service = AsyncMock(return_value=revoked)
    monkeypatch.setattr(admin_router.admin_service, "revoke_admin_session", service)
    response = await _route(admin_router.revoke_session)(_request(token), "sid-old", db=db, current_admin=_admin())
    assert response["id"] == "sid-old"
    service.assert_awaited_once_with(db, 1, "sid-old")


@pytest.mark.asyncio
async def test_dashboard_health_search_and_report_list_delegate(monkeypatch):
    admin = _admin()
    db = MagicMock()
    dashboard = AsyncMock(return_value={"overview": {}, "risk_distribution": {}, "reports": {}, "category_breakdown": {}, "model": {}, "scan_trend": []})
    health = AsyncMock(return_value={"database": "ok", "storage": "ok", "models": "ok", "queue": "ok", "last_check": datetime.now(TH_TIMEZONE)})
    search = AsyncMock(return_value={"items": [], "total": 0})
    reports = AsyncMock(return_value=([{"id": 1}], 1))
    monkeypatch.setattr(admin_router.admin_service, "get_dashboard_stats", dashboard)
    monkeypatch.setattr(admin_router.admin_service, "get_health_status", health)
    monkeypatch.setattr(admin_router.admin_service, "global_search", search)
    monkeypatch.setattr(admin_router.admin_service, "get_reports", reports)

    assert (await _route(admin_router.get_dashboard)(_request(), db=db, current_admin=admin))["overview"] == {}
    assert (await _route(admin_router.get_health)(_request(), db=db, current_admin=admin))["database"] == "ok"
    assert (await _route(admin_router.search_global)(_request(), "needle", db=db, current_admin=admin))["total"] == 0
    listed = await _route(admin_router.get_reports)(_request(), page=2, limit=10, status="pending", category="fake_slip", search="x", db=db, current_admin=admin)
    assert listed["page"] == 2 and listed["total"] == 1
    reports.assert_awaited_once_with(db, 2, 10, "pending", "fake_slip", "x")


@pytest.mark.asyncio
async def test_export_route_functions_create_list_get_cancel_download(monkeypatch, tmp_path):
    admin = _admin()
    db = MagicMock()
    db.commit = AsyncMock()
    job = SimpleNamespace(id="job-1", admin_id=1, status="queued", file_path=None, created_at=datetime.now(TH_TIMEZONE))

    create = AsyncMock(return_value=job)
    process = AsyncMock()
    monkeypatch.setattr(admin_router.export_service, "create_export_job", create)
    monkeypatch.setattr(admin_router.export_service, "process_export_job", process)
    tasks = BackgroundTasks()
    req = SimpleNamespace(model_dump=lambda: {"include_metadata": True})
    created = await _route(admin_router.create_export_job)(_request(), req, tasks, db=db, current_admin=admin)
    assert created is job
    create.assert_awaited_once_with(db, 1, {"include_metadata": True})
    assert len(tasks.tasks) == 1

    db.scalar = AsyncMock(return_value=1)
    db.execute = AsyncMock(return_value=_scalar_result(items=[job]))
    listed = await _route(admin_router.list_export_jobs)(_request(), page=1, limit=20, db=db, current_admin=admin)
    assert listed["total"] == 1 and listed["items"] == [job]

    db.execute = AsyncMock(return_value=_scalar_result(one=job))
    assert await _route(admin_router.get_export_job)(_request(), "job-1", db=db, current_admin=admin) is job
    canceled = await _route(admin_router.cancel_export_job)(_request(), "job-1", db=db, current_admin=admin)
    assert canceled["message"] == "Job canceled"
    assert job.status == "canceled"
    export_file = tmp_path / "dataset.zip"
    export_file.write_bytes(b"zip")
    job.status = "succeeded"
    job.file_path = str(export_file)
    db.execute = AsyncMock(return_value=_scalar_result(one=job))
    response = await _route(admin_router.download_export_job)(_request(), "job-1", db=db, current_admin=admin)
    assert response.path == str(export_file)
    assert response.media_type == "application/zip"


@pytest.mark.asyncio
async def test_report_review_route_functions_delegate(monkeypatch):
    admin = _admin()
    db = MagicMock()
    report = SimpleNamespace(id=7, status="reviewing", version=2, admin_note=None, moderated_by=1, moderated_at=datetime.now(TH_TIMEZONE))
    start = AsyncMock(return_value=report)
    review = AsyncMock(return_value=SimpleNamespace(id=7, status="approved", version=3, admin_note="ok", moderated_by=1, moderated_at=report.moderated_at))
    detail = AsyncMock(return_value={"id": 7})
    monkeypatch.setattr(admin_router.admin_service, "start_review_report", start)
    monkeypatch.setattr(admin_router.admin_service, "review_report", review)
    monkeypatch.setattr(admin_router.admin_service, "get_report_detail", detail)

    assert (await _route(admin_router.get_report_detail)(_request(), 7, db=db, current_admin=admin))["id"] == 7
    started = await _route(admin_router.start_review)(7, _request(), {"version": 1}, db=db, current_admin=admin)
    assert started["status"] == "reviewing"
    decision = SimpleNamespace(version=2, status="approved", admin_note="ok")
    reviewed = await _route(admin_router.review_report)(7, decision, _request(), db=db, current_admin=admin)
    assert reviewed["status"] == "approved"


@pytest.mark.asyncio
async def test_user_model_and_audit_route_functions_delegate(monkeypatch):
    admin = _admin()
    db = MagicMock()
    users = AsyncMock(return_value=([{"id": 3}], 1))
    user_detail = AsyncMock(return_value={"id": 3})
    update_user = AsyncMock(return_value={"id": 3, "email": "u@example.test", "role": "user", "is_active": False})
    models = AsyncMock(return_value=([{"id": 2}], 1))
    deployed_model = SimpleNamespace(id=2, version_tag="v2.0.0", is_active=True, deployed_at=datetime.now(TH_TIMEZONE), status="active")
    deploy = AsyncMock(return_value=deployed_model)
    dry_run = AsyncMock(return_value={"success": True, "message": "ok", "details": {}})
    audit = AsyncMock(return_value=([{"id": 9}], 1))
    monkeypatch.setattr(admin_router.admin_service, "get_users", users)
    monkeypatch.setattr(admin_router.admin_service, "get_user_detail", user_detail)
    monkeypatch.setattr(admin_router.admin_service, "update_user", update_user)
    monkeypatch.setattr(admin_router.admin_service, "get_model_versions", models)
    monkeypatch.setattr(admin_router.admin_service, "deploy_model", deploy)
    monkeypatch.setattr(admin_router.admin_service, "dry_run_model", dry_run)
    monkeypatch.setattr(admin_router.admin_service, "get_audit_logs", audit)
    monkeypatch.setattr(admin_router.manager, "broadcast", AsyncMock())

    listed = await _route(admin_router.get_users)(_request(), page=1, limit=20, search="u", db=db, current_admin=admin)
    assert listed["total"] == 1
    assert (await _route(admin_router.get_user)(_request(), 3, db=db, current_admin=admin))["id"] == 3
    req = SimpleNamespace(is_active=False, reason="reason")
    assert (await _route(admin_router.update_user)(3, req, _request(), db=db, current_admin=admin))["is_active"] is False
    model_list = await _route(admin_router.get_models)(_request(), db=db, current_admin=admin)
    assert model_list["total"] == 1
    deploy_req = SimpleNamespace(reason="promote")
    deployed = await _route(admin_router.deploy_model)(_request(), 2, deploy_req, db=db, current_admin=admin)
    assert deployed["is_active"] is True
    assert (await _route(admin_router.dry_run_model)(_request(), 2, db=db, current_admin=admin))["success"] is True

    audit_list = await _route(admin_router.get_audit_logs)(
        _request(), page=1, limit=50, search="needle", action="update_user", entity_type="user", db=db, current_admin=admin
    )
    assert audit_list["total"] == 1
    audit.assert_awaited_once_with(db, 1, 50, "needle", "update_user", "user")
