# Runbook: ScamGuard Admin Portal (Production) — ฉบับ Canonical

> เอกสารนี้คือ runbook ฉบับ canonical เดียว (`wiki/runbook.md`); `Document/admin/runbook.md` เป็นเพียง pointer มาที่นี่ ห้ามแก้ไขแยกสองฉบับ
> สัญลักษณ์ `<...>` คือค่าที่ผู้ปฏิบัติต้องแทนด้วยค่าจริงหน้างาน (เช่น `<JOB_ID>`, `<ADMIN_EMAIL>`, `<IP>`) ห้ามรันคำสั่งทั้งที่ยังมีวงเล็บมุม
> กฎเหล็ก: **backup ก่อนเขียนทุกครั้ง, ระบุเป้าหมายทีละตัว (ทีละ job/session/admin), ตรวจ verify หลังทำทุกขั้น**

## 0. การเข้าถึงเซิร์ฟเวอร์ (SSH)

1. เชื่อมต่อ: `ssh <USER>@<HOST> -p <PORT>` (ตัวอย่าง `<USER>=deploy`, `<HOST>` ดูใน inventory ภายใน — ห้ามใส่ host จริงในเอกสารนี้)
2. ยืนยันตัวตนเครื่อง: ตรวจ fingerprint ครั้งแรกกับ inventory, ตรวจ `whoami && hostname` ตรงกับเครื่องเป้าหมายก่อนรันคำสั่งเขียนทุกครั้ง
3. ตัวแปรฐานข้อมูลอ่านจาก `.env` ฝั่งเซิร์ฟเวอร์เท่านั้น ห้าม hardcode รหัสผ่านในคำสั่ง/เอกสาร (`psql "$DATABASE_URL" -c "..."`)

## 1. วิธีปิดบัญชี Super Admin (Revoke Super Admin — ทีละบัญชี)

1. สำรองแถวก่อนแก้:
   ```bash
   psql "$DATABASE_URL" -c "COPY (SELECT * FROM admins WHERE email = '<ADMIN_EMAIL>') TO '/tmp/admin_backup_<ADMIN_EMAIL_SAFE>.csv' CSV HEADER;"
   ```
2. ปิดสิทธิ์ + ตัดเซสชันของบัญชีนั้นบัญชีเดียวใน transaction เดียว:
   ```bash
   psql "$DATABASE_URL" -c "BEGIN; UPDATE admins SET is_superadmin = FALSE, updated_at = now() WHERE email = '<ADMIN_EMAIL>'; DELETE FROM admin_sessions WHERE admin_id = (SELECT id FROM admins WHERE email = '<ADMIN_EMAIL>'); COMMIT;"
   ```
3. Verify: `psql "$DATABASE_URL" -c "SELECT email, is_superadmin FROM admins WHERE email = '<ADMIN_EMAIL>';"` ต้องได้ `is_superadmin = f` และ `SELECT count(*) FROM admin_sessions WHERE admin_id = (SELECT id FROM admins WHERE email = '<ADMIN_EMAIL>');` ต้องได้ `0`
4. Rollback: นำ CSV ข้อ 1 กลับเข้า (`COPY ... FROM`) หรือ `UPDATE admins SET is_superadmin = TRUE WHERE email = '<ADMIN_EMAIL>';` แล้วบันทึกเหตุผลลง audit

## 2. วิธี Rollback Model (เกณฑ์ตัวเลข + transaction)

เกณฑ์เริ่มต้นในการสั่ง rollback (ปรับได้โดย SRE พร้อมบันทึกเหตุผล):
- False-positive rate > 15% จากงาน review ย้อนหลัง 100 งานติดกัน, หรือ
- Inference P95 > 25 วินาที (ภาพ 1080p) ต่อเนื่อง 15 นาที, หรือ
- Worker OOM/killed ≥ 3 ครั้งใน 1 ชั่วโมง

ขั้นตอน:
1. ผ่าน Admin Portal: เมนู **AI Models** → ค้นหาเวอร์ชันก่อนหน้า → กด **Rollback** (วิธีหลัก)
2. กรณีหน้าเว็บใช้ไม่ได้ — หา ID รุ่นก่อนหน้าแบบ deterministic แล้วสลับใน transaction เดียว:
   ```bash
   psql "$DATABASE_URL" -c "SELECT id, version, deployed_at FROM model_versions WHERE status='active' ORDER BY deployed_at DESC LIMIT 1;"
   psql "$DATABASE_URL" -c "SELECT id, version, deployed_at FROM model_versions WHERE status='inactive' ORDER BY deployed_at DESC LIMIT 1;"
   psql "$DATABASE_URL" -c "BEGIN; UPDATE model_versions SET status='inactive' WHERE id = '<ACTIVE_ID>'; UPDATE model_versions SET status='active' WHERE id = '<PREVIOUS_ID>'; COMMIT;"
   ```
3. Verify: `SELECT id, version, status FROM model_versions WHERE id IN ('<ACTIVE_ID>','<PREVIOUS_ID>');` ต้องมี active exactly 1 แถว; ยิง smoke inference 1 ภาพแล้วตรวจคะแนนอยู่ในช่วงที่คาด
4. Rollback ของ rollback: สลับ `<ACTIVE_ID>`/`<PREVIOUS_ID>` กลับด้วยคำสั่งเดียวกัน

## 3. วิธีจัดการ Export Job ที่ค้างหรือล้มเหลว (ทีละ job — ห้าม restart backend ทั้ง service)

1. ตรวจดิสก์: `df -h /var/lib/postgresql /tmp`
2. ระบุ job ที่ค้างทีละตัว (ไม่แตะ job อื่น):
   ```bash
   psql "$DATABASE_URL" -c "SELECT id, status, updated_at FROM export_jobs WHERE status='running' AND updated_at < now() - interval '1 hour' ORDER BY updated_at;"
   ```
3. หยุดเฉพาะ worker ของ export (ห้าม `systemctl restart scamguard-backend` — จะล้าง RAM ของงานอื่นทั้งหมด): `systemctl stop scamguard-export-worker` แล้วตรวจ `systemctl status scamguard-export-worker`
4. สำรองแถว job นั้นก่อนแก้: `psql "$DATABASE_URL" -c "COPY (SELECT * FROM export_jobs WHERE id = '<JOB_ID>') TO '/tmp/export_job_<JOB_ID>.csv' CSV HEADER;"`
5. ทำเครื่องหมาย failed ทีละ job ใน transaction: `psql "$DATABASE_URL" -c "BEGIN; UPDATE export_jobs SET status='failed', error_message='Manually aborted (<TICKET>)' WHERE id = '<JOB_ID>' AND status='running'; COMMIT;"`
6. Verify: `SELECT id, status FROM export_jobs WHERE id = '<JOB_ID>';` ต้องได้ `failed`; สตาร์ท worker กลับ `systemctl start scamguard-export-worker` แล้วตรวจ status

## 4. วิธีรับมือเหตุการณ์ละเมิดความปลอดภัย (Incident Response — ระบุเป้าหมายทีละตัว)

1. บล็อก IP ทีละ address (ตัวอย่าง nftables; เลือกอย่างใดอย่างหนึ่งให้ตรง OS หน้างาน):
   ```bash
   nft add rule ip filter input ip saddr <IP> drop
   # หรือระดับ Nginx: เพิ่ม "deny <IP>;" ใน server block แล้วรัน "nginx -t && systemctl reload nginx"
   # หรือ AWS WAF: เพิ่ม <IP>/32 เข้า IP set ของ WebACL (ผ่าน console/CLI ตามบัญชีที่ใช้จริง)
   ```
   Verify: `nft list ruleset | grep <IP>` หรือ `nginx -t` ผ่าน + ทดสอบจาก IP นั้นถูกปฏิเสธ
2. เพิกถอนเซสชัน**เฉพาะบัญชีที่กระทบ**ทีละบัญชี (ห้าม `TRUNCATE admin_sessions` — จะเตะแอดมินทุกคนโดยไม่สำรอง):
   ```bash
   pg_dump "$DATABASE_URL" -t admin_sessions -f /tmp/admin_sessions_$(date +%F_%H%M).sql
   psql "$DATABASE_URL" -c "DELETE FROM admin_sessions WHERE admin_id IN (SELECT id FROM admins WHERE email IN ('<ADMIN_EMAIL_1>','<ADMIN_EMAIL_2>'));"
   ```
   Verify: `SELECT count(*) FROM admin_sessions WHERE admin_id IN (...);` ต้องได้ `0`; ไฟล์ backup ข้อบนต้องมีขนาด > 0
3. รัน Backup ฐานข้อมูล (ดูข้อ 5) **ก่อน** เก็บหลักฐานอื่นต่อ
4. ตรวจ `audit_log` ทันที: audit log เป็น append-only (ล็อก UPDATE/DELETE ระดับ policy) จึงเหมาะใช้อ้างอิงย้อนหลัง — แต่**ห้ามอ้างว่าเชื่อถือได้ 100%** ให้ cross-check กับ log ฝั่ง proxy/app เสมอ

## 5. การกู้คืนระบบและฐานข้อมูล (พร้อมเกณฑ์สำเร็จ)

- **Backup**: `bash server/scripts/backup.sh` (เข้ารหัสด้วย OpenSSL)
- **Restore**: `bash server/scripts/restore.sh <backup-file.enc>`
- เกณฑ์สำเร็จ (ต้องผ่านทุกข้อจึงถือว่าเสร็จ):
  1. สคริปต์จบด้วย exit code `0`
  2. ตรวจ checksum ไฟล์ backup ตรงกับค่าที่บันทึกตอนสร้าง (`sha256sum`)
  3. หลัง restore: `SELECT count(*) FROM scans;` (และตารางหลัก) ตรงกับจำนวนที่บันทึกไว้ก่อน backup ±0
  4. ยิง `GET /health` ได้ HTTP 200 และล็อกอินแอดมินทดสอบผ่าน
  5. ทดสอบ restore ลง staging อย่างน้อยไตรมาสละ 1 ครั้งแล้วบันทึกผล
