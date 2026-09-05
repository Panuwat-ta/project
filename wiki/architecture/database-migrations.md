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
│   └── versions/                  # โฟลเดอร์เก็บไฟล์ประวัติการเปลี่ยนแปลงทั้งหมด
│       ├── 001_initial_schema.py
│       ├── 002_add_admins_table.py
│       └── ...
└── app/
    └── models/                    # นิยาม SQLAlchemy ORM Models
        ├── admin.py               # Model ตาราง admins
        ├── user.py                # Model ตาราง users
        ├── scan.py                # Model ตาราง scans
        ├── scam_report.py         # Model ตาราง scam_reports
        ├── audit_log.py           # Model ตาราง audit_log
        └── model_version.py       # Model ตาราง model_versions
```

---

## 3. ขั้นตอนการทำงานและคำสั่งที่ใช้บ่อย (Workflow & Commands)

> [!IMPORTANT]
> ต้องรันคำสั่งทั้งหมดภายในโฟลเดอร์ `server/` และต้องเปิดใช้งาน Virtual Environment (`venv`) พร้อมตั้งค่าตัวแปรสภาพแวดล้อมใน `.env` ให้ครบถ้วนเสมอ

### 3.1 การสร้างไฟล์ Migration อัตโนมัติ (Generate Migration)
เมื่อมีการเพิ่มหรือแก้ไขฟิลด์ในคลาส Model ภายใต้ `server/app/models/` ให้รันคำสั่งเพื่อให้ Alembic เปรียบเทียบความแตกต่างและสร้าง Script อัตโนมัติ:

```bash
alembic revision --autogenerate -m "add admins table and scan title"
```

### 3.2 ตรวจสอบไฟล์ Script ก่อนนำไปใช้จริง
หลังจากสร้างไฟล์ใน `server/migrations/versions/` ให้เปิดตรวจสอบคำสั่งภายในฟังก์ชัน:
- `upgrade()`: คำสั่ง SQL สำหรับปรับใช้การเปลี่ยนแปลงใหม่
- `downgrade()`: คำสั่ง SQL สำหรับย้อนกลับโครงสร้างเดิมกรณีมีปัญหา

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

## 4. ข้อควรระวังและแนวทางปฏิบัติที่ดีที่สุด (Best Practices)

1. **ห้ามแก้ไขสคีมาฐานข้อมูลโดยตรงด้วย SQL Console ในสภาพแวดล้อมจริง:** ทุกการเปลี่ยนแปลงของตาราง คอลัมน์ ดัชนี (Index) หรือ Foreign Key ต้องผ่านไฟล์ Script ของ Alembic เท่านั้น
2. **ไม่ลบไฟล์ Migration ในอดีต:** ไฟล์ประวัติใน `migrations/versions/` ต้องถูกบันทึกลง Git เพื่อให้ผู้พัฒนารายอื่นและ Pipeline CI/CD สามารถ Replicate ฐานข้อมูลได้ตรงกัน 100%
3. **การทดสอบ Downgrade เสมอ:** ทุกครั้งที่เขียน Migration ใหม่ ให้ทดสอบรัน `upgrade` แล้วตามด้วย `downgrade` บนเครื่องทดสอบ เพื่อยืนยันว่าสคริปต์สามารถย้อนกลับได้อย่างสมบูรณ์ ไม่ทิ้งขยะหรือข้อผิดพลาดตกค้าง

---

## 5. ประเด็นสำคัญ

- Alembic ทำงานคู่กับ SQLAlchemy เพื่อสร้างความสอดคล้องระหว่าง Python Code และ PostgreSQL
- ทุก Migration Script ต้องมีทั้งฟังก์ชัน `upgrade()` และ `downgrade()` ที่ทำงานได้จริง
- ข้อมูลการเชื่อมต่อฐานข้อมูลถูกดึงมาจากตัวแปรสภาพแวดล้อม `DATABASE_URL` ใน `.env` ปราศจากการ Hardcode ข้อมูลความลับ

---

## หน้าที่เกี่ยวข้อง

- [[architecture/database-schema|โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล]]
- [[architecture/database-er-diagram|แผนผังความสัมพันธ์ฐานข้อมูล (ER Diagram)]]
- [[architecture/backend-api|Backend API — FastAPI Orchestrator]]
- [[runbook|คู่มือการรันระบบ (Runbook)]]
