## 2026-09-19 03:40 +07 - [Scan Pipeline Seams / test_scan_seams.py + test_scan.py]

- Target: server/tests/utils/test_scan_seams.py (ใหม่), server/tests/api/test_scan.py (เดิม)
- Command: `source venv/bin/activate && python -m pytest tests/utils/test_risk_calculator.py tests/utils/test_risk_module.py tests/utils/test_scan_seams.py tests/api/test_scan.py -q` (workdir: `server/`)
- Result: PASS
- Summary: Total: 18 | Passed: 17 | Failed: 0 | Skipped: 1 | Duration: ~0.7 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[test_cache_miss_returns_none / _roundtrip_and_ttl / _never_raises (ใหม่ 3 เคส)]**:
  - พฤติกรรมที่ผ่าน: FakeCache จำลอง Redis ได้ miss เป็น None, roundtrip คืน dict เดิมพร้อม TTL ตรง `settings.SCAN_CACHE_TTL_SECONDS`, client พัง/None ไม่ raise — พฤติกรรมเดียวกับ inline code เดิม
- **[test_image_store_roundtrip (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: เขียน PNG/heatmap ลง tmp_path ได้ path `{hash}.png` และ `heatmaps/{hash}_heatmap.jpg` ตรง layout เดิม อ่านกลับได้ bytes เดิม
- **[test_scan.py 6 เคส (เดิม)]**:
  - พฤติกรรมที่ผ่าน: API scan flow ผ่านเหมือนเดิมทั้งที่ `process_image_background` รับ deps เพิ่ม (defaults เป็นของจริง) ยืนยันว่า call sites เดิมไม่แตก
- **[risk 7 เคสเดิม]**:
  - พฤติกรรมที่ผ่าน: ผ่านครบ ไม่ได้รับผลกระทบจากงานรอบนี้

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed; 1 skipped เป็นของเดิมใน test_scan.py)
