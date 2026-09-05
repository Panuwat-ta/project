"""Mobile bridge — เรียก flutter test เดิมมารวมรายงาน ไม่ต้องย้ายไฟล์"""
import subprocess
import pytest
from pathlib import Path

MOBILE_ROOT = Path(__file__).resolve().parents[4] / "scam_image_mobile"

@pytest.mark.mobile
def test_flutter_unit():
    """รัน flutter test ทั้งหมดแล้วตรวจว่า pass"""
    if not (MOBILE_ROOT / "pubspec.yaml").exists():
        pytest.skip("scam_image_mobile not found")
    # ตรวจว่า flutter พร้อมไหม
    which = subprocess.run(["which", "flutter"], capture_output=True)
    if which.returncode != 0:
        pytest.skip("flutter not in PATH — skip mobile bridge (รันบนเครื่องที่มี flutter)")

    result = subprocess.run(
        ["flutter", "test", "--reporter=compact"],
        cwd=str(MOBILE_ROOT),
        capture_output=True,
        text=True,
        timeout=300,
    )
    # เก็บ log ไว้ดู
    print(result.stdout[-4000:])
    if result.stderr:
        print(result.stderr[-4000:])
    assert result.returncode == 0, f"flutter test failed\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}"
