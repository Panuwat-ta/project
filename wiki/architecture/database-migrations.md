---
title: "การจัดการการย้ายฐานข้อมูล (Database Migrations)"
category: architecture
tags: [database, postgresql, alembic, sqlalchemy, migration, schema]
sources: [Document/database/alembic.md]
updated: 2026-09-06
---

# การจัดการการย้ายฐานข้อมูล (Database Migrations)

คู่มือและข้อกำหนดการจัดการการเปลี่ยนแปลงโครงสร้างฐานข้อมูล PostgreSQL ของระบบ ScamGuard ด้วยเครื่องมือ Alembic ร่วมกับ SQLAlchemy

---

## 1. ภาพรวมและบทบาทของ Alembic

Alembic ทำหน้าที่เป็นระบบควบคุมเวอร์ชัน (Version Control) สำหรับฐานข้อมูลเชิงสัมพันธ์ PostgreSQL ในระบบ ScamGuard ช่วยให้ทีมพัฒนาสามารถติดตาม ตรวจสอบ และปรับใช้การเปลี่ยนแปลงของสคีมาฐานข้อมูล (เช่น การเพิ่มตาราง `admins`, การเพิ่มคอลัมน์ `title` ใน `scans`) ได้อย่างเป็นระบบ ป้องกันความคลาดเคลื่อนของโครงสร้างฐานข้อมูลระหว่างสภาพแวดล้อม Development, Testing และ Production

---

## 2. โครงสร้างไฟล์และโฟลเดอร์ที่เกี่ยวข้อง

ระบบเก็บไฟล์ที่เกี่ยวข้องกับการ Migration ไว้ภายในโฟลเดอร์ `server/` ดังนี้:

```text
server/
├── alembic.ini                    # ไฟล์กำหนดค่าการทำงานหลักของ Alembic
├── migrations/
│   ├── env.py                     # สคริปต์เชื่อมต่อ SQLAlchemy Models กับฐานข้อมูล
│   ├── script.py.mako             # Template สำหรับสร้างไฟล์ Migration ใหม่
│   └── versions/                  # ไฟล์ประวัติการเปลี่ยนแปลงทั้งหมด 13 ไฟล์ (เรียงตามสายโซ่ down_revision)
│       ├── c5d636f20434_initial_migration.py
│       ├── 45368bf51fde_update_scam_reports_table.py
│       ├── 62cb9477cf84_add_admin_table.py
│       ├── a1b2c3d4e5f6_add_admin_sessions.py
│       ├── c42a6b7c284c_phase_2_structured_audit_and_report_.py
│       ├── 8b428eff3721_phase_2_indexes.py
│       ├── cd0116a8d7bc_add_phase_4_modelversion_fields.py
│       ├── 54e8b8cb0526_add_exportjob_table.py
│       ├── e3844dc4110e_add_append_only_trigger_to_audit_log.py
│       ├── 042de00eee1b_rename_metrics_to_segformer_metrics.py
│       ├── 8bb2e7d0af3c_add_title_to_scan.py
│       ├── 9a0123c45678_add_progress_to_scan.py
│       └── efdfc08f2155_add_xai_explanation_to_scans.py   # head ล่าสุด
└── app/
    └── models/                    # นิยาม SQLAlchemy ORM Models (9 ตาราง)
        ├── user.py                # Model ตาราง users
        ├── admin.py               # Model ตาราง admins
        ├── scan.py                # Model ตาราง scans
        ├── consent.py             # Model ตาราง consent_logs
        ├── report.py              # Model ตาราง scam_reports
        ├── model_version.py       # Model ตาราง model_versions
        ├── admin_session.py       # Model ตาราง admin_sessions
        ├── audit_log.py           # Model ตาราง audit_log
        └── export_job.py          # Model ตาราง export_jobs
```

> [!NOTE]
> ไฟล์ `database/init.sql` มีแค่ `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";` เท่านั้น —
> ไม่ได้สร้างตารางใด ๆ ตารางทั้ง 9 สร้างผ่าน Alembic migrations ข้างต้นทั้งหมด

---

## 3. ขั้นตอนการทำงานและคำสั่งที่ใช้บ่อย (Workflow & Commands)

> [!IMPORTANT]
> ต้องรันคำสั่งทั้งหมดภายในโฟลเดอร์ server และต้องเปิดใช้งาน Virtual Environment พร้อมตั้งค่าตัวแปรสภาพแวดล้อมใน .env ให้ครบถ้วนเสมอ

### 3.1 การสร้างไฟล์ Migration อัตโนมัติ (Generate Migration)
เมื่อมีการเพิ่มหรือแก้ไขฟิลด์ในคลาส Model ภายใต้โฟลเดอร์ models ให้รันคำสั่งเพื่อให้ Alembic เปรียบเทียบความแตกต่างและสร้าง Script อัตโนมัติ:

```bash
alembic revision --autogenerate -m "add admins table and scan title"
```

### 3.2 ตรวจสอบไฟล์ Script ก่อนนำไปใช้จริง
หลังจากสร้างไฟล์ในโฟลเดอร์ migrations/versions ให้เปิดตรวจสอบคำสั่งภายในฟังก์ชัน:
- upgrade: คำสั่ง SQL สำหรับปรับใช้การเปลี่ยนแปลงใหม่
- downgrade: คำสั่ง SQL สำหรับย้อนกลับโครงสร้างเดิมกรณีมีปัญหา

### 3.3 การปรับใช้การเปลี่ยนแปลงไปยังฐานข้อมูล (Upgrade)
รันคำสั่งเพื่ออัปเดตสคีมาของ PostgreSQL ให้เป็นเวอร์ชันล่าสุด:

```bash
alembic upgrade head
```

### 3.4 การตรวจสอบสถานะและประวัติเวอร์ชัน
- ตรวจสอบเวอร์ชันปัจจุบันของฐานข้อมูล:
  ```bash
  alembic current
  ```
- ดูประวัติการ Migration ทั้งหมดตามลำดับเวลา:
  ```bash
  alembic history --verbose
  ```

### 3.5 การย้อนกลับการเปลี่ยนแปลง (Downgrade)
หากเกิดข้อผิดพลาดและต้องการย้อนกลับไปยังเวอร์ชันก่อนหน้า 1 ขั้น:

```bash
alembic downgrade -1
```

---

## 3.6 ประวัติ Migration รายไฟล์ (13 ไฟล์ ตามลำดับสายโซ่)

| ลำดับ | ไฟล์ (revision) | ต่อจาก | สรุปการเปลี่ยนแปลง |
| :--- | :--- | :--- | :--- |
| 1 | `c5d636f20434_initial_migration.py` | — (base) | สร้างตารางตั้งต้น: users, scans, scam_reports, consent_logs, audit_log (แบบย่อ), model_versions (แบบย่อ) |
| 2 | `45368bf51fde_update_scam_reports_table.py` | c5d636f20434 | เพิ่มคอลัมน์ scam_reports: category, platform, reference_url, allow_research_use, admin_note |
| 3 | `62cb9477cf84_add_admin_table.py` | 45368bf51fde | สร้างตาราง admins (is_superadmin) + ย้าย FK audit_log.admin_id และ scam_reports.moderated_by จาก users ไป admins (SET NULL) |
| 4 | `a1b2c3d4e5f6_add_admin_sessions.py` | 62cb9477cf84 | สร้างตาราง admin_sessions (refresh-token rotation, replaced_by ไม่มี FK) |
| 5 | `c42a6b7c284c_phase_2_structured_audit_and_report_.py` | a1b2c3d4e5f6 | เพิ่ม structured audit fields ให้ audit_log (entity_type/id, before/after_state, reason, ip, user_agent, request_id) + version ให้ scam_reports |
| 6 | `8b428eff3721_phase_2_indexes.py` | c42a6b7c284c | เพิ่ม index: audit_log (action, admin_id, created_at, entity_type), scam_reports (category, status, created_at), scans (user_id, created_at) |
| 7 | `cd0116a8d7bc_add_phase_4_modelversion_fields.py` | 8b428eff3721 | เพิ่มฟิลด์ Phase 4 ให้ model_versions: artifact_checksum, framework_compatibility, accuracy/precision/recall, dataset_reference, created_by (FK admins), status, deployment_history |
| 8 | `54e8b8cb0526_add_exportjob_table.py` | cd0116a8d7bc | สร้างตาราง export_jobs (รวม error_message) |
| 9 | `e3844dc4110e_add_append_only_trigger_to_audit_log.py` | 54e8b8cb0526 | สร้าง trigger append-only ของ audit_log (ดู 3.7) |
| 10 | `042de00eee1b_rename_metrics_to_segformer_metrics.py` | e3844dc4110e | ลบ accuracy/precision/recall แล้วเพิ่ม a_acc/m_iou/m_acc/m_dice แทน (ดู 3.8) — downgrade สร้างคอลัมน์เดิมกลับ |
| 11 | `8bb2e7d0af3c_add_title_to_scan.py` | 042de00eee1b | เพิ่มคอลัมน์ title (nullable) ให้ scans |
| 12 | `9a0123c45678_add_progress_to_scan.py` | 8bb2e7d0af3c | เพิ่มคอลัมน์ progress (NOT NULL, default 0) ให้ scans |
| 13 | `efdfc08f2155_add_xai_explanation_to_scans.py` | 9a0123c45678 | เพิ่มคอลัมน์ xai_explanation (nullable) ให้ scans — head ล่าสุด |

### 3.7 Trigger append-only ของ audit_log (`e3844dc4110e`)

- `upgrade` สร้างฟังก์ชัน `prevent_audit_log_modification()` (plpgsql, `RAISE EXCEPTION` เสมอ)
  แล้วสร้าง trigger `trg_prevent_audit_log_modification` แบบ `BEFORE UPDATE OR DELETE ON audit_log
  FOR EACH ROW` — จึงห้าม UPDATE และ DELETE ทุกแถวที่ระดับฐานข้อมูล (INSERT ยังได้ปกติ)
- `downgrade` ลบ trigger ก่อน (`DROP TRIGGER IF EXISTS ... ON audit_log`) แล้วลบ function
  (`DROP FUNCTION IF EXISTS prevent_audit_log_modification()`)

### 3.8 การเปลี่ยนชื่อ metrics โมเดล (`042de00eee1b`)

- migration `cd0116a8d7bc` เคยเพิ่ม `accuracy / precision / recall` ให้ `model_versions`
- migration `042de00eee1b` ลบคอลัมน์ทั้งสามทิ้ง แล้วเพิ่ม `a_acc / m_iou / m_acc / m_dice`
  (SegFormer-style metrics, Float, nullable) แทน — โค้ดปัจจุบัน (`model_version.py`) ใช้ชื่อใหม่นี้

---

## 4. ข้อควรระวังและแนวทางปฏิบัติที่ดีที่สุด (Best Practices)

1. **ห้ามแก้ไขสคีมาฐานข้อมูลโดยตรงด้วย SQL Console ในสภาพแวดล้อมจริง:** ทุกการเปลี่ยนแปลงของตาราง คอลัมน์ ดัชนี (Index) หรือ Foreign Key ต้องผ่านไฟล์ Script ของ Alembic เท่านั้น
2. **ไม่ลบไฟล์ Migration ในอดีต:** ไฟล์ประวัติใน `migrations/versions/` ต้องถูกบันทึกลง Git เพื่อให้ผู้พัฒนารายอื่นและ Pipeline CI/CD สามารถ Replicate ฐานข้อมูลได้ตรงกัน 100%
3. **การทดสอบ Downgrade เสมอ:** ทุกครั้งที่เขียน Migration ใหม่ ให้ทดสอบรัน upgrade แล้วตามด้วย downgrade บนเครื่องทดสอบ เพื่อยืนยันว่าสคริปต์สามารถย้อนกลับได้อย่างสมบูรณ์ ไม่ทิ้งขยะหรือข้อผิดพลาดตกค้าง

---

## 5. ประเด็นสำคัญ

- Alembic ทำงานคู่กับ SQLAlchemy เพื่อสร้างความสอดคล้องระหว่าง Python Code และ PostgreSQL
- ทุก Migration Script ต้องมีทั้งฟังก์ชัน upgrade และ downgrade ที่ทำงานได้จริง
- ข้อมูลการเชื่อมต่อฐานข้อมูลถูกดึงมาจากตัวแปรสภาพแวดล้อม DATABASE_URL ใน .env ปราศจากการ Hardcode ข้อมูลความลับ

---

## หน้าที่เกี่ยวข้อง

- [[architecture/database-schema|โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล]]
- [[architecture/database-er-diagram|แผนผังความสัมพันธ์ฐานข้อมูล (ER Diagram)]]
- [[architecture/backend-api|Backend API — FastAPI Orchestrator]]
- [[runbook|คู่มือการรันระบบ (Runbook)]]
