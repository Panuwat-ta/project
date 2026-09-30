# Source Verification Legacy Backfill — 2026-09-21

## ขอบเขต
ปรับข้อมูล Scan เดิมที่เกิดจาก implementation เก่า ซึ่งใช้ `source_score=20` ขณะ Source Verification ยังไม่เชื่อมต่อจริง ให้ตรง canonical contract ปัจจุบัน

## 1. ข้อมูลก่อนแก้
- Scan ทั้งหมด: 16 แถว
- แถวที่มี legacy `source_score=20`: 16 แถว
- แถวที่ `total_risk_score` ต่างเมื่อคำนวณโดยตัด Source ที่ unavailable ออก: 4 แถว
- ผลต่างสูงสุด: 9 คะแนน
- Risk Grade ที่จะเปลี่ยน: 0 แถว

## 2. การแก้ไข
- ทำ mutation ผ่าน SQLAlchemy transaction
- เปลี่ยน legacy `source_score` จาก 20 เป็น 0 เพื่อเป็น DB compatibility placeholder
- คำนวณ `total_risk_score` ใหม่จาก Textual + Visual เท่านั้น
- หากเกิด exception ให้ rollback transaction ทั้งชุด
## 3. ผลหลังแก้
- Backfill สำเร็จ: 16 แถว
- แถวที่ total score เปลี่ยนจริง: 4 แถว
- แถวที่ Risk Grade เปลี่ยน: 0 แถว
- `source_score=20` คงเหลือ: 0 แถว
- `source_score=0` หลัง backfill: 16 แถว
- Canonical total mismatch หลัง verify: 0 แถว

## 4. Regression Verification
- Targeted Server: 10/10 PASS หลัง mutation
- Broad Server: 54 passed, 1 skipped, 0 failed
- Admin regression: 5/5 PASS + lint/build PASS
- Mobile contract compatibility: 19/19 PASS
- `git diff --check` และ staged diff-check PASS
- Impeccable detector: `[]`
- Independent `agy`: `NO_CONFIRMED_P0_P2`

หมายเหตุ: ไม่มี schema migration ในรอบนี้ เพราะ column เดิมยังคง `NOT NULL`; ค่า 0 ใช้เป็น storage placeholder เท่านั้น และ API ไม่เปิดเป็น Source evidence เมื่อสถานะ unavailable