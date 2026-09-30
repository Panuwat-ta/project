from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock
import uuid

import pytest

from app.core.config import TH_TIMEZONE
from app.models.admin import Admin
from app.models.admin_session import AdminSession
from app.services import admin_service


def _result(*, first=None, all_items=None, scalar_one=None):
    result = MagicMock()
    result.scalars.return_value.first.return_value = first
    result.scalars.return_value.all.return_value = all_items or []
    result.scalar_one_or_none.return_value = scalar_one
    return result


def test_admin_service_pure_path_helpers(tmp_path):
    assert admin_service._to_media_url(None) is None
    assert admin_service._to_media_url("./uploads/a/b/image.png") == "/uploads/a/b/image.png"
    file_path = tmp_path / "export.zip"
    file_path.write_bytes(b"zip")
    assert admin_service._resolve_export_file(str(file_path)) == str(file_path)
    assert admin_service._resolve_export_file(str(tmp_path / "missing.zip")) is None
@pytest.mark.asyncio
async def test_create_and_revoke_admin_session_round_trip(monkeypatch):
    db = MagicMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    admin = Admin(id=5, email="admin@example.test", is_active=True, is_superadmin=True)

    sid = await admin_service.create_admin_session(
        db, admin, "refresh-token", ip="127.0.0.1", user_agent="pytest", sid="sid-1"
    )
    assert sid == "sid-1"
    db.add.assert_called_once()
    created = db.add.call_args.args[0]
    assert isinstance(created, AdminSession)
    assert created.admin_id == 5
    assert created.ip_address == "127.0.0.1"

    result = _result(first=created)
    db.execute = AsyncMock(return_value=result)
    revoked = await admin_service.revoke_admin_session(db, 5, "sid-1")
    assert revoked is created
    assert created.revoked_at is not None
@pytest.mark.asyncio
async def test_expire_admin_session_revokes_and_expires_immediately():
    future = datetime.now(TH_TIMEZONE) + timedelta(days=1)
    session = SimpleNamespace(admin_id=5, revoked_at=None, expires_at=future)
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(first=session))
    db.commit = AsyncMock()

    expired = await admin_service.expire_admin_session(db, 5, "sid-1")

    assert expired is session
    assert session.revoked_at is not None
    assert session.expires_at <= datetime.now(TH_TIMEZONE)
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_register_admin_refresh_attempt_uses_atomic_redis_window(monkeypatch):
    import app.core.redis as redis_core

    redis = MagicMock()
    redis.eval = AsyncMock(side_effect=[1, 2])
    monkeypatch.setattr(redis_core, "redis_client", redis)

    first = await admin_service.register_admin_refresh_attempt("family-1")
    second = await admin_service.register_admin_refresh_attempt("family-1")

    assert (first, second) == (1, 2)
    assert redis.eval.await_count == 2
    first_args = redis.eval.await_args_list[0].args
    second_args = redis.eval.await_args_list[1].args
    assert first_args[1] == 1
    assert first_args[2] == second_args[2]
    assert first_args[2].startswith("admin:refresh-attempts:")
    assert first_args[3] == 60


@pytest.mark.asyncio
async def test_register_admin_refresh_attempt_falls_back_when_redis_is_unreachable(monkeypatch):
    import app.core.redis as redis_core

    redis = MagicMock()
    redis.eval = AsyncMock(side_effect=ConnectionError("redis unavailable"))
    monkeypatch.setattr(redis_core, "redis_client", redis)
    family = "outage-family"
    key = f"admin:refresh-attempts:{admin_service.hash_token(family)}"
    admin_service._admin_refresh_fallback.pop(key, None)

    try:
        counts = [await admin_service.register_admin_refresh_attempt(family) for _ in range(61)]
    finally:
        admin_service._admin_refresh_fallback.pop(key, None)

    assert counts[0] == 1
    assert counts[59] == 60
    assert counts[60] == 61


@pytest.mark.asyncio
async def test_user_detail_reports_real_monthly_scan_count_and_recent_scan_status():
    created = datetime(2026, 9, 1, tzinfo=timezone.utc)
    user = SimpleNamespace(
        id=9,
        email="user@example.test",
        full_name="User",
        role="user",
        is_active=True,
        created_at=created,
        updated_at=created,
    )
    scan = SimpleNamespace(
        id=uuid.uuid4(),
        raw_image_url="./uploads/test.png",
        total_risk_score=55,
        visual_score=50,
        created_at=created,
        status="completed",
    )

    db = MagicMock()
    db.execute = AsyncMock(side_effect=[
        _result(first=user),
        _result(all_items=[scan]),
        _result(all_items=[]),
    ])
    async def scalar_side_effect(stmt):
        sql = str(stmt)
        if "FROM scans" in sql and "created_at" in sql:
            return 2
        if "FROM scans" in sql:
            return 5
        if "FROM scam_reports" in sql and "status =" in sql:
            return 0
        if "FROM scam_reports" in sql:
            return 3
        return 0

    db.scalar = AsyncMock(side_effect=scalar_side_effect)
    detail = await admin_service.get_user_detail(db, 9)

    assert detail["total_scans"] == 5
    assert detail["stats"]["scans_this_month"] == 2
    assert detail["recent_scans"][0]["status"] == "completed"


@pytest.mark.asyncio
async def test_global_search_short_query_is_empty_without_db_calls():
    db = MagicMock()
    db.execute = AsyncMock()
    result = await admin_service.global_search(db, " ")
    assert result == {"items": [], "total": 0}
    db.execute.assert_not_awaited()
@pytest.mark.asyncio
async def test_health_status_marks_database_error_when_probe_fails(monkeypatch):
    import app.core.redis as redis_core

    db = MagicMock()
    db.execute = AsyncMock(side_effect=RuntimeError("db unavailable"))
    redis = MagicMock()
    redis.ping = AsyncMock(return_value=True)
    monkeypatch.setattr(redis_core, "redis_client", redis)
    status = await admin_service.get_health_status(db)
    assert status["database"] == "error"
    assert status["storage"] == "ok"
    assert status["models"] == "ok"
    assert status["queue"] == "ok"


@pytest.mark.asyncio
async def test_dry_run_model_reports_missing_artifact_without_spawning_worker(tmp_path):
    model = SimpleNamespace(
        id=3,
        version_tag="v9.9.9",
        file_path=str(tmp_path / "missing.onnx"),
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(first=model))
    result = await admin_service.dry_run_model(db, 3)
    assert result["success"] is False
    assert result["details"]["error"] == "File missing"


def test_read_eval_metrics_uses_latest_valid_run(tmp_path):
    run = tmp_path / "test_eval" / "20260921_220000"
    run.mkdir(parents=True)
    (run / "metrics.json").write_text(
        '{"aAcc": 91.0, "mIoU": 82.0, "mAcc": 85.0, "mDice": 88.0}',
        encoding="utf-8",
    )
    metrics = admin_service._read_eval_metrics(tmp_path)
    assert metrics == {"a_acc": 0.91, "m_iou": 0.82, "m_acc": 0.85, "m_dice": 0.88}
@pytest.mark.asyncio
async def test_rotate_admin_session_revokes_old_and_creates_replacement():
    old = SimpleNamespace(
        id="old-sid",
        admin_id=5,
        revoked_at=None,
        replaced_by=None,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(first=old))
    db.add = MagicMock()
    db.commit = AsyncMock()

    access, refresh, new_sid = await admin_service.rotate_admin_session(
        db,
        "old-sid",
        {"sub": "5", "role": "admin"},
        ip="127.0.0.1",
        user_agent="pytest",
    )

    assert access and refresh and new_sid
    assert old.revoked_at is not None
    assert old.replaced_by == new_sid
    replacement = db.add.call_args.args[0]
    assert replacement.id == new_sid
    assert replacement.admin_id == 5
@pytest.mark.asyncio
async def test_dashboard_stats_aggregate_counts_and_active_users():
    today = datetime.now(timezone.utc)
    active_model = SimpleNamespace(
        version_tag="v1.2.3",
        deployed_at=today,
        a_acc=0.91,
        m_iou=0.82,
        m_acc=0.85,
        m_dice=0.88,
    )

    scan_users = _result(all_items=[1, 2])
    report_users = _result(all_items=[2, 3])
    categories = MagicMock()
    categories.all.return_value = [("fake_slip", 2), ("other", 1)]
    model_result = MagicMock()
    model_result.scalar_one_or_none.return_value = active_model
    trend = _result(all_items=[today])

    db = MagicMock()
    db.execute = AsyncMock(side_effect=[scan_users, report_users, categories, model_result, trend])
    db.scalar = AsyncMock(side_effect=[10, 100, 5, 30, 80, 50, 30, 20, 8, 2, 1, 3, 2, 4])

    result = await admin_service.get_dashboard_stats(db)
    assert result["overview"]["active_users_today"] == 3
    assert result["overview"]["total_scans"] == 100
    assert result["risk_distribution"] == {"low": 50, "medium": 30, "high": 20}
    assert result["category_breakdown"] == {"fake_slip": 2, "other": 1}
    assert result["model"]["active_version"] == "v1.2.3"
    assert len(result["scan_trend"]) == 7
@pytest.mark.asyncio
async def test_get_reports_maps_related_user_scan_and_media_url():
    scan_id = uuid.uuid4()
    report = SimpleNamespace(
        id=7,
        user_id=9,
        scan_id=scan_id,
        category="fake_slip",
        reason="reason",
        platform="Facebook",
        reference_url=None,
        allow_research_use=True,
        status="pending",
        admin_note=None,
        moderated_by=None,
        moderated_at=None,
        created_at=datetime.now(timezone.utc),
        version=1,
    )
    user = SimpleNamespace(id=9, email="u@example.test", full_name="User")
    scan = SimpleNamespace(id=scan_id, raw_image_url="./uploads/raw.png", total_risk_score=85, visual_score=80)
    db = MagicMock()
    db.scalar = AsyncMock(return_value=1)
    db.execute = AsyncMock(side_effect=[
        _result(all_items=[report]),
        _result(all_items=[user]),
        _result(all_items=[scan]),
    ])

    items, total = await admin_service.get_reports(db, page=1, limit=20)
    assert total == 1
    assert items[0]["user"]["email"] == "u@example.test"
    assert items[0]["scan"]["thumbnail_url"] == "/uploads/raw.png"
    assert items[0]["scan"]["total_risk_score"] == 85
@pytest.mark.asyncio
async def test_start_review_moves_pending_report_to_reviewing_and_audits(monkeypatch):
    report = SimpleNamespace(
        id=7,
        status="pending",
        version=2,
        moderated_by=None,
        moderated_at=None,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=lambda: report))
    db.add = MagicMock()
    db.commit = AsyncMock()
    broadcast = AsyncMock()
    monkeypatch.setattr(admin_service.manager, "broadcast", broadcast)

    updated = await admin_service.start_review_report(db, 7, 1, 2)
    assert updated.status == "reviewing"
    assert updated.version == 3
    assert updated.moderated_by == 1
    assert db.add.call_args.args[0].action == "report_start_review"
    broadcast.assert_awaited_once_with({"type": "refresh_dashboard"})


@pytest.mark.asyncio
async def test_review_report_approve_updates_version_and_audits(monkeypatch):
    report = SimpleNamespace(
        id=7,
        status="reviewing",
        version=3,
        admin_note=None,
        moderated_by=1,
        moderated_at=None,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=lambda: report))
    db.add = MagicMock()
    db.commit = AsyncMock()
    broadcast = AsyncMock()
    monkeypatch.setattr(admin_service.manager, "broadcast", broadcast)
    decision = SimpleNamespace(version=3, status="approved", admin_note="verified")

    updated = await admin_service.review_report(db, 7, 1, decision)
    assert updated.status == "approved"
    assert updated.version == 4
    assert updated.admin_note == "verified"
    assert db.add.call_args.args[0].action == "report_approved"
    broadcast.assert_awaited_once_with({"type": "refresh_dashboard"})


@pytest.mark.asyncio
async def test_get_model_versions_preserves_registry_metrics():
    model = SimpleNamespace(
        id=1,
        version_tag="v1.0.0",
        file_path="/tmp/model.onnx",
        is_active=True,
        deployed_at=None,
        artifact_checksum="sha256:abc",
        framework_compatibility="onnx",
        a_acc=0.9,
        m_iou=0.8,
        m_acc=0.85,
        m_dice=0.82,
        dataset_reference="dataset-v1",
        created_by=1,
        status="active",
        deployment_history=[],
    )
    db = MagicMock()
    db.scalar = AsyncMock(return_value=1)
    db.execute = AsyncMock(return_value=_result(all_items=[model]))
    items, total = await admin_service.get_model_versions(db)
    assert total == 1
    assert items[0]["version_tag"] == "v1.0.0"
    assert items[0]["m_iou"] == 0.8
@pytest.mark.asyncio
async def test_get_users_returns_activity_counts():
    created = datetime.now(timezone.utc)
    user = SimpleNamespace(
        id=4,
        email="user@example.test",
        full_name="User",
        role="user",
        is_active=True,
        created_at=created,
        updated_at=created,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(all_items=[user]))
    db.scalar = AsyncMock(side_effect=[1, 12, 3])
    items, total = await admin_service.get_users(db, 1, 20)
    assert total == 1
    assert items[0]["total_scans"] == 12
    assert items[0]["total_reports"] == 3


@pytest.mark.asyncio
async def test_update_user_changes_status_and_broadcasts(monkeypatch):
    created = datetime.now(timezone.utc)
    user = SimpleNamespace(
        id=4,
        email="user@example.test",
        full_name="User",
        role="user",
        is_active=True,
        created_at=created,
        updated_at=created,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(first=user))
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    broadcast = AsyncMock()
    monkeypatch.setattr(admin_service.manager, "broadcast", broadcast)

    result = await admin_service.update_user(
        db, 4, 1, SimpleNamespace(is_active=False, reason="abuse")
    )
    assert result["is_active"] is False
    audit = db.add.call_args.args[0]
    assert audit.action == "update_user"
    assert audit.reason == "abuse"
    broadcast.assert_awaited_once_with({"type": "refresh_dashboard"})
@pytest.mark.asyncio
async def test_get_audit_logs_returns_filtered_page_and_total():
    log = SimpleNamespace(id=1, action="update_user")
    count_result = MagicMock()
    count_result.scalar_one.return_value = 1
    items_result = _result(all_items=[log])
    db = MagicMock()
    db.execute = AsyncMock(side_effect=[count_result, items_result])

    items, total = await admin_service.get_audit_logs(
        db,
        page=1,
        limit=25,
        search="user",
        action="update_user",
        entity_type="user",
    )
    assert total == 1
    assert items == [log]


@pytest.mark.asyncio
async def test_deploy_model_switches_registry_state_without_touching_env(monkeypatch, tmp_path):
    model_file = tmp_path / "model.onnx"
    model_file.write_bytes(b"onnx")
    target = SimpleNamespace(
        id=2,
        version_tag="v2.0.0",
        file_path=str(model_file),
        is_active=False,
        status="inactive",
        deployed_at=None,
        deployment_history=None,
    )
    previous = SimpleNamespace(id=1, version_tag="v1.0.0", is_active=True, status="active")
    db = MagicMock()
    db.execute = AsyncMock(side_effect=[
        _result(first=target),
        _result(all_items=[previous]),
    ])
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    switch = MagicMock()
    monkeypatch.setattr(admin_service, "_switch_serving_model", switch)

    result = await admin_service.deploy_model(db, 2, 1, "promote")
    assert result is target
    assert target.is_active is True
    assert target.status == "active"
    assert previous.is_active is False
    assert previous.status == "inactive"
    assert target.deployment_history[0]["reason"] == "promote"
    switch.assert_called_once_with(str(model_file))

@pytest.mark.asyncio
async def test_deploy_model_locks_target_and_active_rows(monkeypatch, tmp_path):
    from sqlalchemy.dialects import postgresql

    model_file = tmp_path / "model.onnx"
    model_file.write_bytes(b"onnx")
    target = SimpleNamespace(id=2, version_tag="v2.0.0", file_path=str(model_file), is_active=False, status="inactive", deployed_at=None, deployment_history=[])
    previous = SimpleNamespace(id=1, version_tag="v1.0.0", is_active=True, status="active")
    statements = []

    async def execute(stmt):
        statements.append(str(stmt.compile(dialect=postgresql.dialect())))
        return _result(first=target) if len(statements) == 1 else _result(all_items=[previous])

    db = MagicMock()
    db.execute = AsyncMock(side_effect=execute)
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    monkeypatch.setattr(admin_service, "_switch_serving_model", MagicMock())

    await admin_service.deploy_model(db, 2, 1, "promote")
    assert len(statements) == 2
    assert all("FOR UPDATE" in sql for sql in statements)


@pytest.mark.asyncio
async def test_dry_run_model_success_uses_shared_onnx_runner(monkeypatch, tmp_path):
    model_file = tmp_path / "model.onnx"
    model_file.write_bytes(b"x" * 1024)
    model = SimpleNamespace(id=3, version_tag="v3.0.0", file_path=str(model_file))
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(first=model))
    runner = MagicMock(return_value={
        "latency_ms": 12.5,
        "returncode": 0,
        "stdout_json": {"visual_risk_score": 77},
        "stderr_text": "",
    })
    monkeypatch.setattr(admin_service, "run_onnx_worker", runner)

    result = await admin_service.dry_run_model(db, 3)
    assert result["success"] is True
    assert result["details"]["latency_ms"] == 12.5
    assert result["details"]["compatibility"] == "Passed"
    assert result["details"]["test_prediction"] == "Score: 77%"
    runner.assert_called_once()


def test_iter_local_model_versions_is_read_only_and_returns_deployable_artifacts():
    entries = list(admin_service._iter_local_model_versions())
    for version_tag, onnx_path, version_dir in entries:
        assert version_tag.startswith("v")
        assert onnx_path.endswith(".onnx")
        assert version_dir.name == version_tag
        assert version_dir.is_dir()


@pytest.mark.asyncio
async def test_sync_model_registry_backfills_metrics_and_registers_new_model(monkeypatch, tmp_path):
    existing_dir = tmp_path / "v1.0.0"
    new_dir = tmp_path / "v2.0.0"
    existing_dir.mkdir()
    new_dir.mkdir()
    existing_onnx = existing_dir / "model.onnx"
    new_onnx = new_dir / "model.onnx"
    existing_onnx.write_bytes(b"existing")
    new_onnx.write_bytes(b"new-model")
    existing = SimpleNamespace(
        version_tag="v1.0.0", a_acc=None, m_iou=None, m_acc=None, m_dice=None,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(all_items=[existing]))
    db.add = MagicMock()
    db.commit = AsyncMock()
    monkeypatch.setattr(
        admin_service,
        "_iter_local_model_versions",
        lambda: iter([
            ("v1.0.0", str(existing_onnx), existing_dir),
            ("v2.0.0", str(new_onnx), new_dir),
        ]),
    )
    monkeypatch.setattr(
        admin_service,
        "_read_eval_metrics",
        lambda version_dir: {
            "a_acc": 0.91, "m_iou": 0.82, "m_acc": 0.85, "m_dice": 0.88,
        },
    )

    added = await admin_service.sync_model_registry(db)

    assert existing.a_acc == 0.91
    assert existing.m_iou == 0.82
    assert "v1.0.0 (metrics)" in added
    assert "v2.0.0" in added
    db.add.assert_called_once()
    created = db.add.call_args.args[0]
    assert created.version_tag == "v2.0.0"
    assert created.file_path == str(new_onnx)
    assert str(created.artifact_checksum).startswith("sha256:")
    assert created.m_iou == 0.82
    db.commit.assert_awaited_once()


def test_switch_serving_model_updates_runtime_without_touching_env_files(monkeypatch):
    import os
    from pathlib import Path
    from app.core.config import settings

    old_setting = settings.ONNX_MODEL_PATH
    old_env = os.environ.get("ONNX_MODEL_PATH")
    monkeypatch.setattr(Path, "exists", lambda self: False)
    try:
        admin_service._switch_serving_model("/tmp/safe-test-model.onnx")
        assert settings.ONNX_MODEL_PATH == "/tmp/safe-test-model.onnx"
        assert os.environ["ONNX_MODEL_PATH"] == "/tmp/safe-test-model.onnx"
    finally:
        settings.ONNX_MODEL_PATH = old_setting
        if old_env is None:
            os.environ.pop("ONNX_MODEL_PATH", None)
        else:
            os.environ["ONNX_MODEL_PATH"] = old_env


@pytest.mark.asyncio
async def test_admin_health_reports_queue_error_when_redis_is_unavailable(monkeypatch):
    import app.core.redis as redis_core

    db = MagicMock()
    db.execute = AsyncMock(return_value=MagicMock())
    monkeypatch.setattr(redis_core, "redis_client", None)

    status = await admin_service.get_health_status(db)

    assert status["database"] == "ok"
    assert status["queue"] == "error"
    assert status["last_check"].tzinfo is not None
    assert status["last_check"].utcoffset() == timedelta(hours=7)


@pytest.mark.asyncio
async def test_report_detail_hides_missing_optional_heatmap(tmp_path):
    created = datetime.now(timezone.utc)
    raw = tmp_path / "raw.png"
    raw.write_bytes(b"raw")
    missing_heatmap = tmp_path / "missing_heatmap.jpg"
    report = SimpleNamespace(
        id=12, user_id=9, scan_id=uuid.uuid4(), category="fake_slip",
        reason="runtime report", platform="Facebook", reference_url=None,
        allow_research_use=True, status="pending", admin_note=None,
        moderated_by=None, moderated_at=None, created_at=created, version=1,
    )
    user = SimpleNamespace(id=9, email="u@example.test", full_name="User")
    scan = SimpleNamespace(
        id=report.scan_id, image_hash="abc", raw_image_url=str(raw),
        heatmap_image_url=str(missing_heatmap), total_risk_score=80,
        visual_score=75, text_score=70, exif_data={}, ocr_text="",
        scam_keywords_found=[], ai_gen_probability=None,
        created_at=created, status="completed",
    )
    db = MagicMock()
    db.execute = AsyncMock(side_effect=[
        _result(scalar_one=report),
        _result(first=user),
        _result(first=scan),
    ])
    db.scalar = AsyncMock(return_value=1)

    detail = await admin_service.get_report_detail(db, 12)

    assert detail["scan"]["raw_image_url"] == "/uploads/raw.png"
    assert detail["scan"]["heatmap_image_url"] is None


def test_media_url_preserves_nested_upload_path(monkeypatch, tmp_path):
    upload_root = tmp_path / "uploads"
    nested = upload_root / "heatmaps" / "evidence.jpg"
    nested.parent.mkdir(parents=True)
    nested.write_bytes(b"heatmap")
    monkeypatch.setattr(admin_service.settings, "LOCAL_UPLOAD_DIR", str(upload_root))

    url = admin_service._to_media_url(str(nested), require_exists=True)

    assert url == "/uploads/heatmaps/evidence.jpg"


@pytest.mark.asyncio
async def test_admin_last_login_uses_latest_root_session_timestamp():
    expected = datetime.now(TH_TIMEZONE)
    db = MagicMock()
    db.scalar = AsyncMock(return_value=expected)

    actual = await admin_service.get_admin_last_login_at(db, 7)

    assert actual == expected
    stmt = db.scalar.await_args.args[0]
    sql = str(stmt.compile(compile_kwargs={"literal_binds": True})).upper()
    assert "MAX(ADMIN_SESSIONS.CREATED_AT)" in sql
    assert "REPLACED_BY IS NOT NULL" in sql
    assert "NOT IN" in sql
