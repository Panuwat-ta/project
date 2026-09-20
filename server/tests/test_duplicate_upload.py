import io
import uuid

import pytest
from fastapi import UploadFile
from PIL import Image

from app.services.scan_service import create_scan_task


class FakeDb:
    def __init__(self):
        self.added = []

    def add(self, instance):
        self.added.append(instance)

    async def commit(self):
        return None

    async def refresh(self, instance):
        if instance.id is None:
            instance.id = uuid.uuid4()


def _image_bytes() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (32, 32), color="black").save(buffer, format="PNG")
    return buffer.getvalue()


@pytest.mark.asyncio
async def test_duplicate_uploads_keep_same_hash_but_create_distinct_scan_records():
    content = _image_bytes()
    db = FakeDb()

    scan1, _bytes1, hash1 = await create_scan_task(
        UploadFile(filename="first.png", file=io.BytesIO(content)), 1, db, "First"
    )
    scan2, _bytes2, hash2 = await create_scan_task(
        UploadFile(filename="second.png", file=io.BytesIO(content)), 1, db, "Second"
    )

    assert hash1 == hash2
    assert scan1.id != scan2.id
    assert scan1.title == "First"
    assert scan2.title == "Second"
    assert db.added == [scan1, scan2]
