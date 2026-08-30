# Runbook: ScamGuard Admin Portal (Production)

เอกสารนี้ระบุขั้นตอนการทำงาน (SOP) ในกรณีฉุกเฉินและงานบำรุงรักษาในระดับ Production

## 1. วิธีปิดบัญชี Super Admin (Revoke Super Admin)
หากพบว่าบัญชี Super Admin ถูกแฮ็กหรือเข้าข่ายต้องสงสัย สามารถปิดใช้งานได้ดังนี้:
1. SSH เข้าไปที่เซิร์ฟเวอร์
2. รันสคริปต์ Database:
   ```bash
   psql -U admin -d scamguard_db -c "UPDATE admins SET is_superadmin = FALSE WHERE email = 'target@example.com';"
   ```
3. หากต้องการปิดการล็อกอินชั่วคราวทั้งหมด:
   ```bash
   psql -U admin -d scamguard_db -c "DELETE FROM admin_sessions WHERE admin_id = (SELECT id FROM admins WHERE email = 'target@example.com');"
   ```

## 2. วิธี Rollback Model หากเจอโมเดลมีปัญหา
หากโมเดลใหม่ตรวจจับผิดพลาดมากเกินไป หรือกินทรัพยากรมาก ให้ดำเนินการย้อนกลับโมเดล:
1. ล็อกอินเข้า Admin Portal
2. ไปที่เมนู **AI Models**
3. ค้นหาโมเดลเวอร์ชันก่อนหน้าในตาราง และกดปุ่ม **Rollback**
4. หากหน้าเว็บใช้งานไม่ได้ ให้รัน SQL:
   ```bash
   psql -U admin -d scamguard_db -c "UPDATE model_versions SET status='inactive' WHERE status='active'; UPDATE model_versions SET status='active' WHERE id = 'ID_ของรุ่นก่อนหน้า';"
   ```

## 3. วิธีจัดการ Export Job ที่ค้างหรือล้มเหลว
Export Job ค้างสถานะ `running` เกิน 1 ชั่วโมง:
1. ตรวจสอบพื้นที่ดิสก์: `df -h`
2. รีสตาร์ทเซอร์วิส Backend เพื่อล้างงานที่ค้างใน RAM: `systemctl restart scamguard-backend`
3. แก้ไขสถานะงานในฐานข้อมูลเป็น Failed:
   ```bash
   psql -U admin -d scamguard_db -c "UPDATE export_jobs SET status = 'failed', error_message = 'Manually aborted' WHERE status = 'running';"
   ```

## 4. วิธีรับมือเหตุการณ์ละเมิดความปลอดภัย (Incident Response)
หากตรวจพบการดึงข้อมูลผิดปกติ หรือถูกโจมตีแบบ DDoS:
1. บล็อก IP ในระดับ Nginx ทันที (หรือ AWS WAF)
2. สั่งเตะผู้ใช้งาน Admin ทุกคนออกจากระบบ (Revoke All Sessions):
   ```bash
   psql -U admin -d scamguard_db -c "TRUNCATE admin_sessions;"
   ```
3. รัน Backup ฐานข้อมูล (ดูข้อ 5)
4. ตรวจสอบ `audit_log` ทันทีเพื่อหากิจกรรมผิดปกติ เนื่องจาก Audit Log ของเราเป็นแบบ Append-Only และถูกล็อกการ UPDATE/DELETE ทำให้ข้อมูลเชื่อถือได้ 100%

## 5. การกู้คืนระบบและฐานข้อมูล
ใช้สคริปต์ในโฟลเดอร์ `server/scripts/`:
- **Backup**: `bash server/scripts/backup.sh` (จะเข้ารหัสด้วย OpenSSL)
- **Restore**: `bash server/scripts/restore.sh <backup-file.enc>`
