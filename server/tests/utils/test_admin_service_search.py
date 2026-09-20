import uuid
from types import SimpleNamespace

import pytest

from app.services.admin_service import global_search


class FakeResult:
    def __init__(self, values):
        self.values = values

    def scalars(self):
        return self.values


class FakeDb:
    def __init__(self, scan):
        self.scan = scan

    async def execute(self, stmt):
        sql = str(stmt)
        if "FROM scans" in sql:
            return FakeResult([self.scan])
        return FakeResult([])


@pytest.mark.asyncio
async def test_global_search_scan_uses_canonical_risk_fields():
    scan = SimpleNamespace(
        id=uuid.uuid4(),
        total_risk_score=85,
        visual_score=85,
    )
    result = await global_search(FakeDb(scan), str(scan.id)[:8])
    scan_items = [item for item in result["items"] if item["type"] == "scan"]
    assert len(scan_items) == 1
    assert "Risk Score: 85%" in scan_items[0]["subtitle"]
    assert "Grade: high" in scan_items[0]["subtitle"]
