---
title: "โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล"
category: architecture
tags: [PostgreSQL, Redis, cache, cloud-storage, schema, ACID]
sources: [design/architecture.md, design/server.md, database/ER_Diagram.md]
updated: 2026-09-06
---

# โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล

ระบบใช้ Storage 3 ประเภทร่วมกัน: PostgreSQL สำหรับข้อมูลเชิงสัมพันธ์, Redis สำหรับ Cache และ Cloud Object Storage สำหรับไฟล์

---

## PostgreSQL — ฐานข้อมูลหลัก

**หน้าที่:** เก็บข้อมูลเชิงสัมพันธ์ที่มีโครงสร้างทั้งหมดด้วย ACID Transaction

### ตารางหลัก (9 ตาราง)

| ตาราง | คำอธิบาย |
| :--- | :--- |
| users | บัญชีผู้ใช้: email, hashed password, full name, role (user/researcher/admin), is_active, created_at, updated_at |
| admins | บัญชีผู้ดูแลระบบแยกตาราง, คอลัมน์ is_superadmin (Boolean, default False) |
| scans | รายการ Scan: id UUID, user_id, image_hash SHA-256, raw_image_url, heatmap_image_url, title, text_score, visual_score, source_score, total_risk_score, exif_data, ocr_text, scam_keywords_found, reverse_search_results, ai_gen_probability, xai_explanation, status, progress, created_at, completed_at (ระดับความเสี่ยงคำนวณตอนแสดงผล) |
| scam_reports | รายงาน Scam จากผู้ใช้: scan_id, category, reason, platform, reference_url, allow_research_use, status (pending/reviewing/approved/rejected), admin_note, moderated_by/at, version |
| consent_logs | ประวัติการยินยอม PDPA แบบตรวจสอบย้อนหลังได้: user_id, system_consent, research_consent, ip_address, user_agent, created_at (สร้างตอน register) |
| model_versions | Registry โมเดล: version_tag, file_path, is_active, deployed_at, artifact_checksum, framework_compatibility (onnx), metrics a_acc, m_iou, m_acc, m_dice (เปลี่ยนชื่อจาก accuracy/precision/recall โดย migration 042de00eee1b), dataset_reference, created_by, status, deployment_history |
| admin_sessions | Session/refresh-token rotation ของ admin |
| audit_log | บันทึก Append-only ของการกระทำโดย Admin: admin_id, action, entity_type, entity_id, before_state, after_state, reason, ip_address, user_agent, request_id, details, created_at |
| export_jobs | งาน export dataset: admin_id, status, progress, total_rows, file_size_bytes, error_message, file_path, manifest, filter_config, expires_at, created_at, completed_at |

### Append-only trigger ของ audit_log

ตาราง audit_log เป็น append-only ที่ระดับฐานข้อมูล: trigger `trg_prevent_audit_log_modification`
(`BEFORE UPDATE OR DELETE ON audit_log FOR EACH ROW`) เรียกฟังก์ชัน
`prevent_audit_log_modification()` ซึ่ง `RAISE EXCEPTION` เสมอ จึงห้าม UPDATE และ DELETE
ทุกแถว (สร้างโดย migration `e3844dc4110e`; downgrade ลบ trigger แล้วลบ function)

### Field ที่เกี่ยวกับ PDPA

consent จะถูกส่งผ่าน body ของ register แล้วบันทึกเป็นแถวใหม่ใน consent_logs:

- system_consent — ยินยอมให้ประมวลผลรูปภาพ (จำเป็น ถ้าไม่ยินยอมใช้แอปไม่ได้)
- research_consent — ยินยอมให้นำรูปภาพไป Train AI (ไม่บังคับ ถอนได้)

---

## Redis — Cache Store

**หน้าที่:** ค้นหาภาพที่เคยวิเคราะห์แล้วด้วยความเร็วสูง เพื่อหลีกเลี่ยงการรัน AI ซ้ำ

### การทำงาน

1. เมื่อรับรูปภาพ API จะคำนวณ **SHA-256** ของไฟล์รูป
2. ใช้ Hash นั้นเป็น key ใน Redis (TTL 30 วัน)
3. **Cache Hit** — พบ Hash ใน Redis → ใช้ผล inference ที่แคชไว้ → ส่งคืนทันที (เป้าหมาย < 3 วินาที)
4. **Cache Miss** — ไม่พบ Hash → รัน Pipeline ครบ → เก็บใน PostgreSQL → เขียน Hash ลง Redis

### Cache Invalidation

- Redis Key หมดอายุตาม TTL ที่ตั้งไว้
- เมื่อ Deploy โมเดลใหม่ (น้ำหนักใหม่) Cache entry เก่าอาจ Stale — Admin สั่ง Cache Invalidation แบบ Forced ได้

---

## Local Filesystem Storage

**หน้าที่:** เก็บไฟล์รูป (normalize เป็น PNG) ที่ไม่เหมาะเก็บในฐานข้อมูล Relational

### โครงสร้างการจัดเก็บ

```
uploads/
  รูปต้นฉบับ (normalize lossless PNG)
  heatmaps/
    Heatmap overlay (mask-to-heatmap)
```

DB เก็บเฉพาะ path ของรูปต้นฉบับและ Heatmap

### Access Control

- เสิร์ฟผ่าน /uploads ให้ admin portal preview ได้

### การเก็บรักษาข้อมูล

- รูปต้นฉบับที่อัปโหลด **ถูกลบออกจาก Storage** เมื่อวิเคราะห์เสร็จ (ตาม PDPA: เก็บน้อยที่สุด)
- ไฟล์ Heatmap เก็บไว้เชื่อมกับ Scan Record เพื่อแสดงในประวัติสแกน
- ถ้าผู้ใช้ถอนยินยอมการวิจัย รูปภาพของพวกเขาถูกลบออกจาก Research Dataset

---

## ประเด็นสำคัญ

- PostgreSQL คือ Source of Truth สำหรับข้อมูลที่มีโครงสร้างทั้งหมด (9 ตาราง)
- Redis คือ Performance Optimization — ล้างและสร้างใหม่ได้ (TTL 30 วัน)
- Local filesystem รับผิดชอบไฟล์รูปทั้งหมด ฐานข้อมูล Relational เก็บแค่ Path/URL
- PDPA Compliance บังคับที่ระดับ Storage: เก็บน้อยที่สุด, consent ผ่าน register body ไปยัง consent logs, ถอนได้

---

## หน้าที่เกี่ยวข้อง

- [[architecture/database-er-diagram|แผนผังความสัมพันธ์ฐานข้อมูล (ER Diagram)]]
- [[architecture/database-migrations|การจัดการการย้ายฐานข้อมูล (Database Migrations)]]
- [[architecture/backend-api|Backend API — FastAPI Orchestrator]]
- [[architecture/admin-portal|สถาปัตยกรรม Admin Portal]]
- [[architecture/ai-inference-service|AI Inference Service]]
- [[architecture/system-architecture|สถาปัตยกรรมระบบรวม]]
- [[requirements/non-functional-requirements|ข้อกำหนดความต้องการที่ไม่ใช่ฟังก์ชัน]]
- [[concepts/risk-scoring|การคำนวณคะแนนความเสี่ยง]]
