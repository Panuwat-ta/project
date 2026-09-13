# การออกแบบฐานข้อมูล (Database Design)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)
### หลักสูตรวิศวกรรมซอฟต์แวร์ สาขาวิศวกรรมไฟฟ้า คณะวิศวกรรมศาสตร์ มทร.ล้านนา (เชียงใหม่ ดอยสะเก็ด)

เอกสารฉบับนี้อธิบายการออกแบบฐานข้อมูล PostgreSQL ของระบบ เพื่อให้สมาชิกทีม
(รวมคนที่ไม่เคยแตะส่วนนี้) อ่านแล้วเข้าใจว่าแต่ละตารางเก็บอะไร ใครใช้ และทำไมออกแบบแบบนี้
สคีมาจริงอยู่ใน `server/app/models/*.py` เปลี่ยนผ่าน Alembic migration เท่านั้น

---

## 🔗 เอกสารที่เกี่ยวข้อง (Related Documents)

* รายละเอียดสคีมาฉบับเต็ม (database/ER_Diagram.md)
* การออกแบบระบบหลังบ้านและเซิร์ฟเวอร์ (design/server.md)
* เอกสารสถาปัตยกรรมระบบ (design/architecture.md)
* แผนภาพระดับ C1–C3 (Document/docs/03_Software_Architecture.md §2–§4)
* ประวัติ migration (wiki/architecture/database-migrations.md)

---

## 1. ภาพรวมและวัตถุประสงค์

ฐานข้อมูลหลักใช้ **PostgreSQL 15** เก็บข้อมูลเชิงสัมพันธ์ทั้งหมดด้วย ACID รวม 11 ตาราง
(9 หลัก + 2 archive) แบ่งเป็น 5 กลุ่มตามหน้าที่:

| กลุ่ม | ตาราง | หน้าที่สั้น ๆ |
| :--- | :--- | :--- |
| บัญชีผู้ใช้ | users, admins, admin_sessions | ใครใช้ระบบ + session ของแอดมิน |
| งานหลัก | scans, scam_reports | ผลสแกนภาพ + รีพอร์ตหลอกลวง |
| PDPA | consent_logs (+ archive) | หลักฐานการยินยอม |
| โมเดล AI | model_versions | registry โมเดลแต่ละเวอร์ชัน |
| ตรวจสอบ/งานหลังบ้าน | audit_log (+ archive), export_jobs | บันทึกการกระทำ admin + งาน export |

- **ขอบเขต**: เฉพาะ PostgreSQL — Redis (cache ผล inference ตาม `image_hash` + queue)
  และ file storage (รูปภาพ) อยู่นอกขอบเขต
- **ผู้ใช้ฐานข้อมูล**: FastAPI backend (role `scamguard_app` สิทธิ์แค่ DML),
  migration/ops (owner `scamguard`), สคริปต์ purge/archive ผ่าน cron

## 2. กฎธุรกิจที่ฝังอยู่ใน schema (Business Rules)

- **BR-01**: สมัครต้องมี consent row; หลักฐาน consent ต้องรอดพ้นการลบ user (ตัด link + ล้าง PII แทนการลบ)
- **BR-02**: การกระทำของ admin บันทึกแบบ append-only แก้/ลบไม่ได้ (trigger ระดับ DB)
- **BR-03**: หมวดรีพอร์ตใช้ 7 ค่า canonical ตรงกับ API `GET /reports/categories` (มติ DOC-08)
- **BR-04**: score ทุกมิติและ progress อยู่ในช่วง 0–100 (CHECK ระดับ DB ไม่ใช่แค่โค้ด)
- **BR-05**: scan+ไฟล์ >90 วันลบ, log >1 ปี archive, ไฟล์ export เก็บ 7 วัน
- **BR-06**: app มีสิทธิ์แค่ DML; DDL เป็นของ owner (least-privilege)

## 3. รายละเอียดตาราง (Data Dictionary)

> อ่านตารางแบบนี้: **คอลัมน์** = ชื่อฟิลด์ | **ชนิด** = ชนิด PostgreSQL |
> **ข้อกำหนด** = NOT NULL/ค่าเริ่มต้น/unique/index | **คำอธิบาย** = เก็บอะไร ใช้ที่ไหน

### 3.1 users — บัญชีผู้ใช้ทั่วไป

ใครสมัครผ่านแอปจะได้แถวที่นี่ 1 แถว มี 2 บทบาท: `user` (ผู้ใช้ทั่วไป) กับ `researcher`
(นักวิจัยที่ขอใช้ข้อมูลได้) — **ไม่มี `admin`** เพราะบัญชีแอดมินแยกไปตาราง `admins`
(บังคับด้วย CHECK ระดับ DB ใครยัด `admin` เข้ามาจะโดน reject)

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK, index | รหัสผู้ใช้ (run ต่อกัน) |
| email | String(255) | NOT NULL, unique, index | อีเมลล็อกอิน ซ้ำไม่ได้ ค้นหาบ่อยเลย index |
| hashed_password | String(255) | NOT NULL | รหัสผ่านแบบ bcrypt hash (ไม่มี plain text) |
| full_name | String(100) | nullable | ชื่อแสดง |
| role | String(20) | NOT NULL, default `user`, CHECK (`user`,`researcher`) | บทบาท |
| is_active | Boolean | default True | False = บัญชีถูกปิด (ลบบัญชี = ตั้ง False ไม่ได้ลบแถว) |
| created_at / updated_at | TIMESTAMPTZ | default now() | เวลาสมัคร/แก้ไขล่าสุด (โซน UTC เก็บแบบ timezone-aware) |

### 3.2 admins — บัญชีผู้ดูแลระบบ (แยกตาราง)

แยกจาก users เพราะ auth คนละระบบ (มี session/refresh-token ของตัวเอง มี flag superadmin)
และสิทธิ์ `/admin/*` ต้องเป็น superadmin เท่านั้น

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK, index | รหัสแอดมิน |
| email | String(255) | NOT NULL, unique, index | อีเมลล็อกอินหลังบ้าน |
| hashed_password | String(255) | NOT NULL | bcrypt hash |
| full_name | String(100) | nullable | ชื่อแสดง |
| is_active | Boolean | default True | ปิดบัญชีแอดมิน |
| is_superadmin | Boolean | default False | True = เข้า `/admin/*` ได้ (บังคับที่ dependency `require_super_admin`) |
| created_at / updated_at | TIMESTAMPTZ | default now() | เวลาสร้าง/แก้ไขล่าสุด |

### 3.3 scans — ผลสแกนรูปภาพ (ตารางหัวใจของระบบ)

อัปโหลด 1 ครั้ง = 1 แถว เก็บตั้งแต่ไฟล์ดิบยันคะแนน 4 มิติ (ข้อความ/ภาพ/แหล่งที่มา/รวม)
id เป็น UUID (เดาไม่ได้ ต่างจากตารางอื่นที่เป็น Integer)
`total_risk_score` เก็บซ้ำจากผลรวม 3 มิติโดยตั้งใจ (แลกให้ query เร็ว คุมด้วย CHECK + service)

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | UUID | PK, default uuid4 | รหัสสแกน (public-facing ผ่าน API) |
| user_id | Integer → users.id | nullable, index, ลบ user แล้วเป็น NULL | เจ้าของสแกน |
| image_hash | String(64) | NOT NULL, index | SHA-256 ของไฟล์ (ใช้ dedup + เป็น key cache Redis) |
| title | String(255) | nullable | หัวข้อที่ผู้ใช้ตั้ง |
| raw_image_url | String(512) | NOT NULL | path ไฟล์ต้นฉบับ (เก็บแค่ pointer ไม่ใช่ blob) |
| heatmap_image_url | String(512) | nullable | path ภาพ heatmap อธิบายผล AI |
| text_score / visual_score / source_score / total_risk_score | Integer | NOT NULL, default 0, CHECK 0–100 | คะแนน 4 มิติ |
| exif_data | JSONB | nullable | ข้อมูล EXIF จากไฟล์ (schema ไม่นิ่งเลยใช้ JSONB) |
| ocr_text | Text | nullable | ข้อความที่ OCR อ่านได้ |
| scam_keywords_found | JSONB | nullable | คำหลอกลวงที่เจอ |
| reverse_search_results | JSONB | nullable | ผลค้นหาภาพย้อนกลับ |
| ai_gen_probability | Float | default 0.0 | ความน่าจะเป็นที่ภาพสร้างด้วย AI |
| xai_explanation | Text | nullable | คำอธิบายผลแบบอ่านรู้เรื่อง |
| status | String(20) | NOT NULL, default `pending`, CHECK 8 ค่า | `pending → uploading → queued → processing_source/visual/text → completed/failed` |
| progress | Integer | NOT NULL, default 0, CHECK 0–100 | % ความคืบหน้าให้ mobile แสดง |
| created_at | TIMESTAMPTZ | default now(), index | เวลาสแกน (ลบอัตโนมัติเมื่อเกิน 90 วัน) |
| updated_at | TIMESTAMPTZ | default now(), auto-update | แก้ไขล่าสุด |
| completed_at | TIMESTAMPTZ | nullable | เวลาประมวลผลเสร็จ |

### 3.4 scam_reports — รีพอร์ตภาพหลอกลวงจากผู้ใช้

ผู้ใช้กดรายงานภาพ → แอดมินพิจารณา (pending → reviewing → approved/rejected)
`version` กันกรณีแอดมิน 2 คนแก้พร้อมกัน; ลบ scan/user แล้วรีพอร์ตอยู่ต่อ (link เป็น NULL)

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK | รหัสรายงาน |
| user_id | Integer → users.id | nullable, index, SET NULL | คนรายงาน |
| scan_id | UUID → scans.id | nullable, index, SET NULL | สแกนที่ถูกรายงาน |
| category | String(50) | NOT NULL, default `other`, index, CHECK 7 ค่า | `romance_scam, online_shopping, fake_slip, investment, identity_theft, ai_deepfake, other` |
| reason | Text | NOT NULL | เหตุผล (API บังคับ ≥10 ตัวอักษร) |
| platform | String(50) | nullable | เจอจากแพลตฟอร์มไหน (เช่น LINE, Facebook) |
| reference_url | String(512) | nullable | ลิงก์อ้างอิง (เก็บอย่างเดียว ไม่ fetch) |
| allow_research_use | Boolean | NOT NULL, default False | ยินยอมให้ใช้เป็นข้อมูลวิจัย |
| status | String(20) | NOT NULL, default `pending`, index, CHECK 4 ค่า | ขั้นตอนพิจารณา |
| admin_note | Text | nullable | หมายเหตุแอดมิน (บังคับกรอกเมื่อ reject/ส่งกลับ) |
| moderated_by | Integer → admins.id | nullable, index, SET NULL | แอดมินคนพิจารณา |
| moderated_at | TIMESTAMPTZ | nullable | เวลาพิจารณา |
| created_at | TIMESTAMPTZ | default now(), index | เวลารายงาน |
| version | Integer | NOT NULL, default 1 | กัน concurrent edit |

### 3.5 consent_logs — หลักฐานการยินยอม (PDPA)

สร้าง 1 แถวตอนสมัครทุกครั้ง เป็นหลักฐานทางกฎหมายจึง**ห้ามหาย**:
ลบ user แล้วแถวอยู่ต่อแบบ `user_id = NULL` + trigger ล้าง ip/user_agent อัตโนมัติ

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK | รหัส log |
| user_id | Integer → users.id | nullable, index, SET NULL | เจ้าของ consent (NULL = user ถูกลบแล้ว) |
| system_consent | Boolean | NOT NULL, default True | ยินยอมประมวลผล (ไม่ยินยอมใช้แอปไม่ได้) |
| research_consent | Boolean | NOT NULL, default False | ยินยอมให้ใช้ train AI (ถอนได้) |
| ip_address | String(45) | nullable | IP ตอนยินยอม (ถูกล้างเมื่อลบ user) |
| user_agent | Text | nullable | browser/app ตอนยินยอม (ถูกล้างเมื่อลบ user) |
| created_at | TIMESTAMPTZ | default now() | เวลายินยอม |

### 3.6 model_versions — ทะเบียนโมเดล AI

เก็บทุกเวอร์ชันโมเดลที่ deploy (ปัจจุบัน SegFormer) พร้อม metrics ไว้เทียบและ rollback

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK | รหัสเวอร์ชัน |
| version_tag | String(50) | NOT NULL, unique | เช่น `v1.0.4` ซ้ำไม่ได้ |
| file_path | String(512) | NOT NULL | path ไฟล์น้ำหนักโมเดล |
| is_active | Boolean | NOT NULL, default False | ตัวที่ serve จริง (มีได้ตัวเดียวโดย convention ที่ service) |
| deployed_at | TIMESTAMPTZ | default now() | เวลา deploy |
| artifact_checksum | String(256) | nullable | checksum ยืนยันไฟล์ไม่ถูกแก้ |
| framework_compatibility | String(50) | default `onnx` | เฟรมเวิร์กที่รันได้ |
| a_acc / m_iou / m_acc / m_dice | Float | nullable | metrics (เปลี่ยนชื่อจาก accuracy/precision/recall โดย migration `042de00eee1b`) |
| dataset_reference | String(256) | nullable | ชุดข้อมูลที่ใช้เทส |
| created_by | Integer → admins.id | nullable, index, SET NULL | แอดมินคน deploy |
| status | String(50) | NOT NULL, default `inactive`, CHECK 4 ค่า | `pending, active, inactive, failed` |
| deployment_history | JSONB | nullable | ประวัติ deploy/rollback |

### 3.7 admin_sessions — session แอดมิน (refresh-token rotation)

access token ของแอดมินผูกกับแถวนี้ (`sid` ใน JWT) ทำให้เพิกถอนได้จริง
ต่างจาก user ที่เป็น stateless JWT ล้วน

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | String(64) | PK | session id (uuid hex) ตรงกับ `sid` ใน token |
| admin_id | Integer → admins.id | NOT NULL, index, CASCADE | เจ้าของ session (ลบ admin แล้ว session หายด้วย) |
| refresh_hash | String(64) | NOT NULL, unique, index | sha256 ของ refresh token (ไม่เก็บตัวจริง) |
| expires_at | TIMESTAMPTZ | NOT NULL | หมดอายุเมื่อไร |
| revoked_at | TIMESTAMPTZ | nullable, index | เวลาเพิกถอน (logout/refresh หมุน) |
| replaced_by | String(64) | nullable, **ไม่มี FK โดยตั้งใจ** | id session ใหม่ตอน rotation (แลก referential integrity กับความเรียบง่าย) |
| user_agent / ip_address | String(255) / String(64) | nullable | อุปกรณ์ที่ login (ตารางนี้ ip กว้างกว่าตารางอื่นที่ใช้ 45) |
| created_at / last_used_at | TIMESTAMPTZ | default now() / nullable | สร้าง/ใช้ล่าสุด |

### 3.8 audit_log — บันทึกการกระทำของแอดมิน (append-only)

ใครทำอะไรกับข้อมูลไหน เมื่อไร + state ก่อน/หลัง — **ห้าม UPDATE/DELETE ทุกกรณี**
(trigger กันระดับ DB ยกเว้นสคริปต์ archive ที่ผ่านช่อง `SET LOCAL` เท่านั้น)

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | Integer | PK | รหัส log |
| admin_id | Integer → admins.id | nullable, index, SET NULL | คนทำ |
| action | String(100) | NOT NULL, index | เช่น approve_report, deploy_model |
| entity_type / entity_id | String(50/255) | index / nullable | ชนิด+id ของสิ่งที่ถูกกระทำ (`report`, `user`, `model`, `system`) |
| before_state / after_state | JSONB | nullable | snapshot ก่อน/หลัง (ตรวจสอบย้อนหลัง) |
| reason | Text | nullable | เหตุผล |
| ip_address / user_agent / request_id | String(45) / Text / String(100) | nullable | ร่องรอย request |
| details | Text | nullable | ข้อความเสริม (backward compat) |
| created_at | TIMESTAMPTZ | default now(), index | เวลาเกิดเหตุการณ์ |

### 3.9 export_jobs — งาน export dataset

แอดมินสั่ง export → ประมวลผล async → โหลดไฟล์ได้ 7 วันแล้วหมดอายุ (ไฟล์ถูกลบ + mark `expired`)

| คอลัมน์ | ชนิด | ข้อกำหนด | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| id | UUID | PK, default uuid4 | รหัส job |
| admin_id | Integer → admins.id | nullable, index, SET NULL | คนสั่ง |
| status | String(50) | NOT NULL, default `queued`, CHECK 6 ค่า | `queued → running → succeeded/failed/canceled/expired` |
| progress | Float | NOT NULL, default 0.0 | % ความคืบหน้า |
| total_rows / file_size_bytes | Integer / BigInteger | nullable | จำนวนแถว/ขนาดไฟล์ |
| error_message | String | nullable | เหตุผลที่ fail |
| file_path | String(512) | nullable | path ไฟล์ (NULL หลังหมดอายุ) |
| manifest / filter_config | JSONB | nullable / NOT NULL | สรุปไฟล์ / เงื่อนไขที่สั่ง export |
| expires_at | TIMESTAMPTZ | nullable | หมดอายุ (เสร็จ +7 วัน — ตั้งตอน job succeeded ไม่ใช่ตอนสร้าง) |
| created_at / completed_at | TIMESTAMPTZ | NOT NULL now() / nullable | สั่งเมื่อไร/เสร็จเมื่อไร |

### 3.10 audit_log_archive / consent_logs_archive — ที่เก็บ log เกิน 1 ปี

schema เดียวกับตารางจริง + `archived_at`, **ไม่มี FK/trigger** (เก็บสำเนาอย่างเดียว)
ย้ายโดย `server/scripts/archive_old_logs.py` ทุกวันที่ 1 เวลา 04:00 (batch ละ 1000, มี `--dry-run`)

## 4. ความสัมพันธ์ระหว่างตาราง (Relationships)

| จาก → ถึง | แบบ | กติกาตอนลบ (ON DELETE) |
| :--- | :--- | :--- |
| users → scans / scam_reports / consent_logs | 1:N | SET NULL (ข้อมูลอยู่ต่อ, consent ล้าง PII ด้วย trigger) |
| admins → scam_reports / audit_log / model_versions / export_jobs | 1:N | SET NULL (งานอยู่ต่อ) |
| admins → admin_sessions | 1:N | CASCADE (session ไร้ความหมายเมื่อ admin หาย) |
| scans → scam_reports | 1:N | SET NULL (รีพอร์ตอยู่ต่อ) |
| (archive tables) | — | ไม่มี FK ไม่ผูกกับใคร |

## 5. Constraints, Index และเหตุผล

- **Unique**: email ทั้งสองตาราง (ล็อกอินซ้ำไม่ได้), version_tag, refresh_hash
- **CHECK ระดับ DB** (ไม่ใช่แค่โค้ด): role 2 ค่า, scan status 8 ค่า, scores 0–100,
  category 7 ค่า, ทุก status — migration `d4e5f6a7b8c9`
- **Index**: ทุก FK + คอลัมน์ล็อกอิน + คอลัมน์กรองบ่อย (category/status/action/created_at)
  — เหตุผล: join รายงาน–สแกน, หน้ารายการแอดมิน, ค้นหาประวัติ
- **ชนิดข้อมูล**: UUID สำหรับ id ที่โผล่ผ่าน API (เดาไม่ได้), JSONB สำหรับข้อมูล schema ไม่นิ่ง,
  TIMESTAMPTZ ทุกเวลา, string จำกัดขนาดตามใช้จริง, ไม่เก็บ blob ใน DB เลย

## 6. Normalization

อยู่ใน **3NF** ทั้ง schema ยกเว้นที่ยอมรับ 2 จุด:
1. `total_risk_score` เก็บซ้ำจากผลรวม 3 มิติ — แลกให้ query หน้า history เร็ว
2. คอลัมน์ JSONB — ข้อมูล semi-structured ที่ไม่เคย join ไม่คุ้มแตกตาราง

## 7. Security, Retention, Backup

- **Roles**: owner `scamguard` (migration) / `scamguard_app` (app ใช้แค่ DML) — migration `e0f1a2b3c4d5`;
  เปิดใช้ด้วย `ALTER ROLE ... LOGIN PASSWORD` (ops, ห้ามเข้า git)
- **App**: bcrypt, refresh sha256, JWT exp 60m/7d, รหัส 8–128 ตัว, rate limit, ownership check —
  รายงาน OWASP เต็ม `Document/docs/10_OWASP_Audit_2026-09-13.md`
- **Retention**: purge scan+ไฟล์ >90 วัน (daily), archive log >1 ปี (monthly), export 7 วัน
- **Backup**: `backup.sh`/`restore.sh` (AES-256-CBC); ข้อมูลถาวรใน volume `postgres_data`
- ไฟล์รูป: local `./uploads` (dev, ≤20MB) / GCS (production)

## 8. การตัดสินใจออกแบบที่สำคัญ

1. แยกตาราง `admins` — auth คนละระบบ มี session/superadmin ของตัวเอง
2. consent รอดพ้นการลบ user (หลักฐาน PDPA) — SET NULL + trigger ล้าง PII
3. audit append-only ระดับ trigger (BR-02)
4. ไม่ทำ partitioning — ปริมาณ coursework ไม่คุ้ม ใช้ retention คุมขนาดแทน
5. soft-delete บัญชี (`is_active=False`) แทน hard delete — ประวัติ scan/report ไม่ขาดตอน

## 9. Version / Change Log

- Schema เปลี่ยนผ่าน Alembic เท่านั้น (head `e0f1a2b3c4d5`, 18 ไฟล์) —
  ประวัติเต็ม `wiki/architecture/database-migrations.md`
- เอกสารนี้ + `database/ER_Diagram.md` อัปเดตคู่กันทุกครั้งที่เปลี่ยน schema
- เขียนครั้งแรก: 2026-09-13 (สกัดจาก schema + code จริง)
