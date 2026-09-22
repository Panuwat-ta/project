# รายงานปิดงาน P3 Admin หลัง Function Debug

วันที่: 2026-09-22
Branch: `refactoring-admin`
Baseline: `b9b30c88`

## ขอบเขต
รอบนี้ทำต่อจาก function-level debug โดยปิด residual 2 จุดที่เหลือ: การยกเลิก Dataset Export ระหว่างงานขนาดใหญ่ และการแสดง `recent_scans.status` ใน User Detail

ใช้ workflow RED → fix → GREEN, self-review, full regression, WebMCP runtime matrix และ `agy` independent review โดยไม่ commit/push/PR/deploy

## Finding 1: Export cancel ตรวจช้าเกินไป
RED test จำลอง export 205 รายการและ external cancellation พบว่า worker เดิมเขียนครบ 205 รายการก่อนเรียก refresh เพื่อตรวจสถานะ

แก้ให้ checkpoint ทุก 100 รายการ: commit progress → refresh row → ถ้า status=`canceled` ให้หยุดเขียน ZIP, ปิด archive, ลบ partial file, clear `file_path` และคืนสถานะ canceled

หลังแก้ targeted Export suite ผ่าน 7/7 และ test ยืนยันว่า cancellation ถูกตรวจภายใน batch ไม่เกิน 100 รายการ

## Finding 2: User Detail ไม่แสดง scan status
RED test ยืนยันว่าตาราง `การสแกนล่าสุด` ไม่มีคอลัมน์ `สถานะ` ทั้งที่ backend ส่ง `recent_scans.status` แล้ว
เพิ่มคอลัมน์สถานะและใช้ `StatusBadge` แสดงค่าจาก `scan.status` พร้อมปรับ empty-state `colSpan` จาก 4 เป็น 5

ขยาย status mapping ให้รองรับ `processing_source`, `processing_visual`, `processing_text`, `completed` และ alias `canceled` เพื่อไม่แสดง raw backend string

RED component test เดิมแสดง `processing_visual` ตรง ๆ; หลังแก้ targeted frontend tests ผ่าน 16/16

## Finding 3: Finalization race ระหว่าง cancel กับ succeeded
`agy` รอบแรกหลัง P3 fixes ให้ NO_CONFIRMED_P0_P1_P2_P3 แต่ตั้งข้อสังเกตว่ามี race window ระหว่าง final refresh กับ worker commit `succeeded`

self-review สร้าง RED contracts เพิ่มและยืนยัน gap ทั้งสองฝั่ง:
- worker final refresh ไม่ได้ lock row
- cancel endpoint SELECT ไม่ได้ใช้ `FOR UPDATE`

แก้ protocol ให้ worker ใช้ `await db.refresh(job, with_for_update=True)` ก่อน publish success และ cancel endpoint ใช้ `SELECT ... FOR UPDATE` ก่อนอ่าน/เปลี่ยนสถานะ

ผลคือถ้า cancel lock ก่อน worker จะเห็น `canceled` และ cleanup; ถ้า worker lock ก่อน cancel จะรอจนเห็นสถานะ final หลัง worker commit จึงไม่เขียน stale status ทับกัน

Targeted lock/cancel suite หลังแก้ผ่าน 8 tests
## Runtime Validation
WebMCP full-page matrix ถูก rerun หลังเพิ่ม status column

Attempt 1: product routes/layout ทำงาน แต่ `document.modelContext` ไม่พร้อมเพราะ Chrome เปิดเพียง `--enable-webmcp-testing`; จัดเป็น harness setup failure ไม่ใช่ product failure

Attempt 2 เปิดทั้ง `--enable-webmcp-testing` และ `--enable-features=WebMCPTesting`: **40/40 PASS**

User Detail `/admin/users/1` ผ่านครบ mobile/desktop × dark/light, `scanStatusVisible=true`, document overflow=false และ console error=0

## Final Gates
- Admin tests: **39/39 PASS**
- ESLint: **PASS**
- Production build: **PASS**, 2,485 modules, 446 ms
- Server full regression: **132 passed / 3 skipped / 0 failed**
- Admin backend targeted coverage: **74 passed**, overall surface **89%**
- WebMCP matrix: **40/40 PASS**
- `git diff --check`: PASS
- `loop-context --check`: unavailable, RC=127

## Independent Review
`agy` final review หลัง row-lock fix คืน `NO_CONFIRMED_P0_P1_P2_P3`

รอบก่อน row-lock `agy` ชี้ uncertainty เรื่อง finalization race; self-review ไม่รับเป็นข้อสรุปทันที แต่สร้าง RED tests จนยืนยัน missing lock จริงและแก้ก่อนเรียก reviewer ซ้ำ

## Git / Cleanup
Temporary Chrome `9223` และ Vite `5174` ที่เปิดสำหรับ matrix ถูกปิดหลังทดสอบ; Vite เดิม `5173` และ backend `8000` ไม่ถูกหยุด

ยังไม่มี commit, push, amend, reset, PR, merge หรือ deploy จากรอบนี้

## สรุป
Residual P3 ทั้งสองจุดถูกปิด และ concurrency race ที่พบระหว่าง finalization ถูกแก้ด้วย row-lock protocol ทั้ง worker/cancel endpoint ปัจจุบันไม่มี confirmed P0–P3 เหลือใน scope ที่ตรวจรอบนี้
