# รายงาน Admin WebSocket Security Hardening — 2026-09-21

## ปัญหาที่พบ
- Admin dashboard เดิมส่ง access token ผ่าน `?token=...` ใน WebSocket URL
- Uvicorn access log จึงสามารถบันทึก credential ลง log ได้
- WebSocket endpoint เดิมตรวจเพียง JWT `role=admin` แต่ไม่ตรวจ session id, revoked/expired session หรือ `is_superadmin`
- Client reconnect สามารถ schedule ซ้ำจาก error/close และมี timer edge case ตอนยังไม่มี access token

## การแก้ไข
- ย้าย access token ออกจาก URL ไป `Sec-WebSocket-Protocol`
- Server negotiate เฉพาะ protocol `scamguard-admin`; ไม่ echo JWT เป็น selected subprotocol
- Server ตรวจ admin identity, active status, superadmin, `sid`, session ownership, revoked status และ expiry ก่อน accept
- บันทึก `last_used_at` หลัง authentication สำเร็จ
- Client reconnect ใช้ timer เดียวและ reset timer ก่อน connect รอบใหม่
- `onerror` ปิด socket และปล่อยให้ `onclose` เป็นผู้ schedule reconnect เพียงจุดเดียว
## ผลทดสอบ
- Server WebSocket auth tests: `5/5 PASS`
  - active Super Admin session ต่อได้
  - revoked session ถูกปฏิเสธ
  - expired session ถูกปฏิเสธ
  - non-Super Admin ถูกปฏิเสธ
  - legacy query-token ถูกปฏิเสธ
- Admin Node tests รอบสุดท้าย: `7/7 PASS`
- `npm run lint`: PASS
- `npm run build`: PASS, 449 ms ใน final gate
- Production grep: ไม่พบ `?token=` ใน WebSocket URL path (`TOKEN_QUERY_CLEAN`)
- `git diff --check`: PASS
- Impeccable mechanical detector: `[]`

## Independent review
- เรียก `agy` สองรอบแบบ read-only review แล้ว แต่ทั้งสองรอบหมดเวลาโดยไม่คืน verdict
- จึงไม่นับ independent reviewer เป็น PASS และไม่สร้างผล `NO_CONFIRMED_P0_P2` ขึ้นเอง

## ข้อจำกัดที่ยังเปิดอยู่
- Authenticated browser matrix เต็มชุดยังไม่ได้ยืนยัน เนื่องจากไม่มี valid browser Admin session และไม่ได้สร้าง/reset credential เพื่อหลบข้อจำกัดเครื่องมือ
- การส่ง JWT ผ่าน WebSocket subprotocol ป้องกันการรั่วใน URL/access log แบบเดิม แต่ reverse proxy ที่ตั้งค่า log headers เองยังต้องมีนโยบาย redact headers ตาม deployment environment
