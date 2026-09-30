# รายงานทดสอบ Source Verification Contract — 2026-09-21

## 1. ขอบเขตและพฤติกรรมที่ตรวจ
- เป้าหมาย: ทำให้ Source Verification ที่ยังไม่เชื่อม provider จริงไม่สร้างคะแนนสมมติและไม่กระทบ Overall Risk
- Contract ปัจจุบัน: `source_status="unavailable"` และ `source_score=null` ที่ API
- `calculate_risk_score()` ต้องตัดมิติ source ออกจากสูตรเมื่อ score เป็น `None`
- DB ยังเก็บ `source_score=0` เป็น compatibility placeholder เท่านั้น เพราะ column ปัจจุบันเป็น non-null และรอบนี้ไม่ทำ migration
- Enum ที่เตรียมไว้: `unavailable`, `not_checked`, `checked_no_match`, `matches_found`, `error`

## 2. Functional / Contract Verification
- Targeted pytest: `tests/utils/test_risk_module.py`, `tests/utils/test_scan_seams.py`, `tests/api/test_admin_reports.py`
- ผล: 13 passed, 0 failed
- ยืนยันว่า unavailable source คืน `None` และไม่เปลี่ยนคะแนนจาก Textual/Visual
- ยืนยัน `ScanResponse` ซ่อน legacy storage placeholder และ serialize เป็น `source_score=null`
- ยืนยัน Admin Report Detail คืน `source_status="unavailable"` และ `source_score=null`

## 3. Regression / Compatibility Verification
- Broad server suite: `pytest tests --ignore=tests/inference --ignore=tests/api/test_scan_xai_live.py -q`
- ผล final: 54 passed, 1 skipped, 0 failed, 2 dependency warnings
- Admin Portal: `npm test` 5/5, `npm run lint` PASS, `npm run build` PASS (402 ms)
- Mobile compatibility: targeted Flutter tests 19/19 PASS; parser เดิมไม่สร้าง Source factor เมื่อ `source_score` เป็น null
- `git diff --check` PASS และค้นหา `DEFAULT_SOURCE_SCORE` ใน server source ไม่พบแล้ว
- Independent `agy` final review: `NO_CONFIRMED_P0_P2`

## 4. ข้อจำกัด / ความเสี่ยงที่ยังเหลือ
- Read-only audit DB พบ scan 16 แถว และทั้ง 16 แถวยังมี legacy `source_score=20` จาก behavior เดิม
- ใน 4 แถว stored `total_risk_score` ต่างจากค่าที่คำนวณใหม่โดยตัด source ออก สูงสุด 9 คะแนน แต่ไม่ข้าม threshold 40 จึงไม่เปลี่ยน Risk Grade/Distribution
- รอบนี้ไม่ backfill DB และไม่แก้ migration เพื่อรักษา audit history และเพราะ data mutation/schema change ต้องมี human approval แยก
- Inference/live-XAI suite ถูก exclude ตามคำสั่ง broad deterministic gate เดิม; ไม่อ้างว่าได้ทดสอบ live provider เพราะ Source Verification ยังไม่มี provider จริง
