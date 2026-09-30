import io
import uuid

import pytest
from fastapi import UploadFile
from PIL import Image

from app.services.scan_service import create_scan_task
from app.utils.hashing import calculate_image_hash


class FakeDb:
    def __init__(self):
        self.added = []
        self.commits = 0

    def add(self, instance):
        self.added.append(instance)

    async def commit(self):
        self.commits += 1

    async def refresh(self, instance):
        if instance.id is None:
            instance.id = uuid.uuid4()


def _image_bytes() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (32, 32), color="white").save(buffer, format="PNG")
    return buffer.getvalue()


@pytest.mark.asyncio
async def test_create_scan_task_accepts_valid_image_and_initializes_record():
    content = _image_bytes()
    upload = UploadFile(filename="test.png", file=io.BytesIO(content))
    db = FakeDb()

    scan, file_bytes, image_hash = await create_scan_task(upload, 1, db, "Title 1")

    assert file_bytes == content
    assert image_hash == calculate_image_hash(content)
    assert scan.id is not None
    assert scan.user_id == 1
    assert scan.title == "Title 1"
    assert scan.status == "uploading"
    assert scan.progress == 0
    assert scan.risk_grade == "low"
    assert db.added == [scan]
    assert db.commits == 1
