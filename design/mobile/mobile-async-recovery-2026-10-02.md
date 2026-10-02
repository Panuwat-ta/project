# Async recovery — Issue #80

## การเปลี่ยนแปลง

- Scan จำกัด duplicate ของ file path เดิมขณะ upload/polling และใช้ generation ป้องกัน stale status หลัง resume/new scan
- Timeout เก็บ canonical task ID/path, มี deadline timer แยกจาก polling; Retry ติดตาม task เดิมผ่าน AnalysisResumed
- Report ไม่รับ submit ซ้อนระหว่าง pending
- Result ใช้ generation/active task และ in-flight guard; screen dispose หยุด timer/invalidate pending response เฉพาะ task ที่ตนแสดง
- History cache ใช้เฉพาะ network failure และ cache write ไม่ทำให้ fresh response หาย; search responses ใช้ generation และ deletion invalidate fetch เก่า

## หลักฐาน

Full automated suite ผ่าน 684/684, branch 83.13%; focused Scan 20/20 รวม lifecycle test ใหม่หลัง full suite; mobile analyzer 0 issues และ CRLF-aware diff check ผ่าน

รายงาน: `tests_all/tests_report/automate_tests/mobile/issue-80-async-recovery-2026-10-02.md`

## ข้อจำกัด

ไม่มี retry POST อัตโนมัติ และ timeout ที่รู้ task ID ไม่อัปโหลดใหม่ หาก upload ขาดการเชื่อมต่อก่อนรับ ID การกด Retry โดยผู้ใช้เป็นคำขอใหม่; ไม่มีหลักฐาน server idempotency-key ใน contract ปัจจุบัน จึงไม่รับประกัน exactly-once ข้าม network partition

Flutter lifecycle จำลองผ่าน; physical network/TalkBack/native QA และ process recreation/soak อยู่ #77/#81
