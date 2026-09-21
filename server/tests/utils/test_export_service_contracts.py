import json
import uuid
import zipfile
from datetime import datetime, timedelta
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services import export_service
from app.core.config import TH_TIMEZONE


def _result(*, one=None, items=None):
    result = MagicMock()
    result.scalar_one_or_none.return_value = one
    result.scalars.return_value.all.return_value = items or []
    return result


class _SessionContext:
    def __init__(self, db):
        self.db = db

    async def __aenter__(self):
        return self.db

    async def __aexit__(self, exc_type, exc, tb):
        return False


@pytest.mark.asyncio
async def test_cleanup_expired_jobs_removes_file_and_marks_expired(tmp_path):
    expired_file = tmp_path / "old.zip"
    expired_file.write_bytes(b"old")
    job = SimpleNamespace(file_path=str(expired_file), status="succeeded", expires_at=datetime.now(TH_TIMEZONE) - timedelta(days=1))

    db = MagicMock()
    db.execute = AsyncMock(return_value=_result(items=[job]))
    db.commit = AsyncMock()

    await export_service._cleanup_expired_jobs(db)

    assert job.status == "expired"
    assert job.file_path is None
    assert not expired_file.exists()
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_create_export_job_enforces_concurrency_limit(monkeypatch):
    db = MagicMock()
    db.scalar = AsyncMock(return_value=5)
    monkeypatch.setattr(export_service, "_cleanup_expired_jobs", AsyncMock())

    with pytest.raises(HTTPException) as exc:
        await export_service.create_export_job(db, 1, {"include_metadata": True})

    assert exc.value.status_code == 429


@pytest.mark.asyncio
async def test_create_export_job_persists_queued_job(monkeypatch):
    db = MagicMock()
    db.scalar = AsyncMock(return_value=0)
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    monkeypatch.setattr(export_service, "_cleanup_expired_jobs", AsyncMock())

    job = await export_service.create_export_job(db, 7, {"categories": ["fake_slip"]})

    assert job.admin_id == 7
    assert job.status is None or job.status == "queued"
    assert job.filter_config == {"categories": ["fake_slip"]}
    db.add.assert_called_once_with(job)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(job)


@pytest.mark.asyncio
async def test_process_export_job_builds_documented_dataset_zip(monkeypatch, tmp_path):
    image_file = tmp_path / "source.jpg"
    image_file.write_bytes(b"jpeg-bytes")
    scan_id = uuid.uuid4()
    now = datetime.now(TH_TIMEZONE)
    job = SimpleNamespace(
        id=uuid.uuid4(), admin_id=1, status="queued", progress=0.0,
        filter_config={"include_metadata": True}, file_path=None,
        total_rows=None, file_size_bytes=None, error_message=None,
        completed_at=None, expires_at=None, manifest=None,
    )
    report = SimpleNamespace(
        id=42, category="fake_slip", platform="Facebook", reason="fraud",
        created_at=now, moderated_at=now, scan_id=scan_id,
    )
    scan = SimpleNamespace(
        id=scan_id, raw_image_url=str(image_file), total_risk_score=82,
    )

    db = MagicMock()
    calls = {"execute": 0}

    async def execute(stmt):
        calls["execute"] += 1
        if calls["execute"] == 1:
            return _result(one=job)
        if calls["execute"] == 2:
            return _result(items=[report])
        return _result(items=[scan])

    db.execute = AsyncMock(side_effect=execute)
    db.scalar = AsyncMock(return_value=1)
    db.commit = AsyncMock()
    db.add = MagicMock()
    db.refresh = AsyncMock()
    monkeypatch.setattr(export_service, "STORAGE_DIR", str(tmp_path))
    monkeypatch.setattr(export_service, "async_session", lambda: _SessionContext(db))
    monkeypatch.setattr(export_service.manager, "broadcast", AsyncMock())

    await export_service.process_export_job(str(job.id))

    assert job.status == "succeeded"
    archive = tmp_path / f"scamguard_export_{job.id}.zip"
    assert archive.exists()
    with zipfile.ZipFile(archive) as zf:
        names = set(zf.namelist())
        image_name = f"images/fake_slip/{scan_id}.jpg"
        assert image_name in names
        assert "metadata.json" in names
        assert "README.md" in names
        metadata = json.loads(zf.read("metadata.json"))
        assert metadata == [{
            "filename": f"fake_slip/{scan_id}.jpg",
            "category": "fake_slip",
            "risk_score": 82,
            "report_id": 42,
            "reported_at": now.isoformat(),
            "approved_at": now.isoformat(),
        }]
        payload = zf.read("metadata.json").decode("utf-8")
        assert "email" not in payload
        assert "full_name" not in payload


@pytest.mark.asyncio
async def test_running_export_honors_external_cancellation(monkeypatch, tmp_path):
    image_file = tmp_path / "source.jpg"
    image_file.write_bytes(b"jpeg-bytes")
    scan_id = uuid.uuid4()
    now = datetime.now(TH_TIMEZONE)
    job = SimpleNamespace(
        id=uuid.uuid4(), admin_id=1, status="queued", progress=0.0,
        filter_config={"include_metadata": False}, file_path=None,
        total_rows=None, file_size_bytes=None, error_message=None,
        completed_at=None, expires_at=None, manifest=None,
    )
    report = SimpleNamespace(id=1, category="fake_slip", created_at=now, moderated_at=now, scan_id=scan_id)
    scan = SimpleNamespace(id=scan_id, raw_image_url=str(image_file), total_risk_score=80)

    db = MagicMock()
    calls = {"execute": 0, "refresh": 0}
    async def execute(stmt):
        calls["execute"] += 1
        if calls["execute"] == 1:
            return _result(one=job)
        if calls["execute"] == 2:
            return _result(items=[report])
        return _result(items=[scan])

    async def refresh(obj):
        calls["refresh"] += 1
        obj.status = "canceled"

    db.execute = AsyncMock(side_effect=execute)
    db.scalar = AsyncMock(return_value=1)
    db.commit = AsyncMock()
    db.add = MagicMock()
    db.refresh = AsyncMock(side_effect=refresh)

    monkeypatch.setattr(export_service, "STORAGE_DIR", str(tmp_path))
    monkeypatch.setattr(export_service, "async_session", lambda: _SessionContext(db))
    monkeypatch.setattr(export_service.manager, "broadcast", AsyncMock())

    await export_service.process_export_job(str(job.id))

    assert calls["refresh"] >= 1
    assert job.status == "canceled"
    assert not (tmp_path / f"scamguard_export_{job.id}.zip").exists()


@pytest.mark.asyncio
async def test_failed_export_removes_partial_archive(monkeypatch, tmp_path):
    scan_id = uuid.uuid4()
    now = datetime.now(TH_TIMEZONE)
    job = SimpleNamespace(
        id=uuid.uuid4(), admin_id=1, status="queued", progress=0.0,
        filter_config={"include_metadata": True}, file_path=None,
        total_rows=None, file_size_bytes=None, error_message=None,
        completed_at=None, expires_at=None, manifest=None,
    )
    report = SimpleNamespace(id=1, category="fake_slip", created_at=now, moderated_at=now, scan_id=scan_id)
    db = MagicMock()
    calls = {"execute": 0}

    async def execute(stmt):
        calls["execute"] += 1
        if calls["execute"] == 1:
            return _result(one=job)
        if calls["execute"] == 2:
            return _result(items=[report])
        return _result(items=[])
    db.execute = AsyncMock(side_effect=execute)
    db.scalar = AsyncMock(return_value=1)
    db.commit = AsyncMock()
    db.add = MagicMock()
    db.refresh = AsyncMock()
    monkeypatch.setattr(export_service, "STORAGE_DIR", str(tmp_path))
    monkeypatch.setattr(export_service, "async_session", lambda: _SessionContext(db))
    monkeypatch.setattr(export_service.manager, "broadcast", AsyncMock())

    await export_service.process_export_job(str(job.id))

    archive = tmp_path / f"scamguard_export_{job.id}.zip"
    assert job.status == "failed"
    assert "not found" in job.error_message.lower()
    assert not archive.exists()
