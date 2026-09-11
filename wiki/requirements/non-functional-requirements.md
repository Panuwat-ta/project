---
title: "ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements)"
category: requirements
tags: [NFR, performance, security, PDPA, availability, privacy, HTTPS, JWT]
sources: [Document/srs.md, design/architecture.md, Document/objective.md]
updated: 2026-08-02
---

# ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements)

ข้อกำหนดด้านประสิทธิภาพ, ความปลอดภัย, ความเป็นส่วนตัว, และกฎระเบียบต่างๆ

> **Canonical catalog:** `Document/docs/05_Software_Requirement_Specification.md` §3 (NFR-01..09), `06_Requirement_Traceability.md` §5.5, `07_Appendix_A_Full_Traceability_Matrix.md` — นิยามตัวเลข/สูตร/เกณฑ์ทั้งหมดดูที่ Document ที่เดียว ไฟล์นี้เหลือแค่ลิงก์อ้าง + รายละเอียดระดับทดสอบที่ Document ไม่มี

---

## ประสิทธิภาพ — เวลาตอบสนอง (canonical: Document NFR-01)

| ข้อกำหนด | เป้าหมาย (ตาม Document NFR-01) |
| :--- | :--- |
| ความเร็วตอบสนอง — แบบ Cache Hit | <= 3 วินาที (P95, End-to-End; เงื่อนไขภาพ 1080p/4G) |
| ความเร็วตอบสนอง — แบบ Full Inference (Cache Miss) | <= 15 วินาทีต่อภาพ (P50; P95 <= 25s, P99 <= 35s) |
| AI Inference — GPU (NVIDIA T4+) | <= 10 วินาที/ภาพ |
| AI Inference — CPU Fallback | <= 60 วินาที/ภาพ (แสดงคำเตือน "Processing may take longer (CPU mode)") |

**หมายเหตุ:**

- เป้าหมาย Cache Hit 3 วินาที คิดจาก Redis Lookup + PostgreSQL Fetch โดยไม่ต้องมี AI Inference
- เป้าหมาย Full Inference 15 วินาที ครอบคลุมถึง: EXIF + OCR + ตรวจสอบผ่าน API + AI Inference + ผลิต Heatmap + จัดเก็บผลลัพธ์
- ค่าข้างต้นคือเกณฑ์ช่วงทดสอบ (test) ส่วนระดับ SLA ใน Production กำหนดแยกหลัง baseline; Uptime วัดต่อรอบ 30 วัน ไม่นับ Planned Maintenance ที่ประกาศล่วงหน้า

---

## การขยายระบบ (canonical: Document NFR-02 — รองรับผู้ใช้พร้อมกัน ≥ 100 คน)

- Load Testing 100 concurrent users: Cache Hit avg <= 5 วินาที, Cache Miss avg <= 20 วินาที, Error Rate < 1%
- AI Inference scale 1→4 replicas, throughput ≥3x, เสร็จใน 5 นาที @100 concurrent users (รายละเอียดระดับทดสอบ)
- AI Inference Service ออกแบบโครงสร้างให้เป็น Container อิสระ เผื่อรับมือช่วงที่ระบบต้องประมวลผลเยอะจนมีอาการหน่วงได้
- ลดจำนวนการทำงานด้วย Redis Cache เป็นส่วนเสริมเพื่อตอบคำถามโดยไม่ต้องรัน AI (Graceful Degradation สำหรับคำถามเดิมๆ ช่วง High Load)

---

## ความพร้อมใช้งาน (canonical: Document NFR-03 — Uptime ≥ 99.5% + Monitoring/Alerting)

- Uptime >= 99.5% ต่อรอบ 30 วัน ไม่นับ Planned Maintenance (เกณฑ์ช่วงทดสอบ; SLA production กำหนดแยก) + crash-free sessions >= 99.9% (รายละเอียดระดับทดสอบ)
- Monitoring: Prometheus + Grafana (Real-time Dashboard); Alerting: Grafana Alerts + Sentry → Slack/LINE/Email (Error Rate > 5%, P95 > 30s, Uptime < 99.5%, GPU/CPU > 90%)

---

## ความแม่นยำของ AI (canonical: Document NFR-05)

| ตัวชี้วัด | เป้าหมาย (ตาม Document NFR-05) |
| :--- | :--- |
| ความแม่นยำ (Accuracy) การตรวจจับภาพตัดต่อ | >= 85% บน frozen test set 1,000 ภาพ (สคริปต์ประเมินเวอร์ชันคงที่) |
| ค่า mDice การตรวจจับภาพตัดต่อ | >= 85% บน frozen test set เดียวกัน (mDice ใช้เฉพาะงาน segmentation) |
| Precision / Recall (เกณฑ์เสริม) | >= 85% (Document NFR-05 AC-3/AC-4) |

ตาราง metrics ของโมเดล (a_acc, m_iou, m_acc, m_dice) ดูรายละเอียดที่ตาราง model_versions

---

## ความปลอดภัย (canonical: Document NFR-04)

### Transport Security

- ช่องทาง Mobile↔Server ใช้ **TLS 1.3**; API production บังคับ HTTPS ห้ามส่ง password/token ผ่าน URL

- ทุกช่องทางการเชื่อมต่อระหว่าง Mobile App และ Server ใช้โปรโตคอล **HTTPS/TLS Encryption**
- ไม่อนุญาตให้มีการส่งข้อมูลรูปภาพ หรือ รหัสผ่านแบบ Plaintext เด็ดขาด

### Authentication และ Authorization

- **JWT (JSON Web Token)** — ออกให้เพื่อรับรองการ Login และบังคับตรวจสอบทุก Endpoint ป้องกันระดับสิทธิ์ (Access TTL 15 นาที / Refresh TTL 7 วัน)
- นำ Token ไปเก็บใน **Secure Storage** ของสมาร์ตโฟนผู้ใช้
- **RBAC (Role-Based Access Control)** — แยกสิทธิ์ระหว่าง User ธรรมดา และ Admin ป้องกันการละเมิด
- Endpoint ของ Admin ทั้งหมดจะปฏิเสธ Token ผู้ใช้ระดับธรรมดาทันที

### Rate Limiting

| กลุ่มผู้ใช้ | เป้าหมาย (ตาม Document RC-NFR-08) |
| :--- | :--- |
| Guest (ยังไม่ login) | 10 requests/minute |
| Authenticated User | 60 requests/minute |
| Admin | 300 requests/minute |

### ข้อมูล (Data Security; รหัสผ่าน: Argon2id หรือ bcrypt+salt เท่านั้น ห้าม plaintext)

- ไฟล์ชั่วคราวของ worker (original/heatmap ชั่วคราว) ลบอัตโนมัติใน 1 ชม. หลังวิเคราะห์เสร็จ (Minimal Retention)
- ใช้ Presigned URL ซึ่งเป็นลิงก์แบบมีอายุจำกัด เพื่อส่งมอบข้อมูลที่เข้ารหัสให้เฉพาะ Client ไม่มีการเปิดเผย Credential พื้นฐานออกไป

### ความเป็นส่วนตัว PDPA (canonical: Document FR-PDPA-01 + RC-PDPA-04; เดิมเรียก NFR-10 wiki-local — ยกเลิกเลขนี้แล้ว)

กฎหมายว่าด้วยการคุ้มครองข้อมูลส่วนบุคคลของไทย (PDPA) มีผลบังคับใช้กับโครงการนี้อย่างเคร่งครัด

### Privacy by Design

- ระบบออกแบบมาให้จัดเก็บข้อมูลน้อยที่สุดเท่าที่จำเป็น
- ไม่เก็บข้อมูลอื่นที่ไม่อยู่ในจุดประสงค์

### การจัดการความยินยอม (Consent Management — Document FR-PDPA-01)

มีกระบวนการแสดง Consent ให้ยินยอม 2 ระดับ ตอนที่เปิดแอปพลิเคชันครั้งแรก:

1. **System Consent (บังคับ)** — ต้องยินยอมให้ประมวลผลรูปภาพเพื่อการตรวจสอบ หากไม่ให้ จะไม่สามารถใช้งานระบบได้เลย
2. **Research Consent (ไม่บังคับ/เลือกได้)** — การยินยอมให้เก็บรวบรวมรูปภาพ (แบบนิรนาม) สู่ Dataset งานวิจัย AI สามารถเปิดและปิด (Opt-in / Opt-out) ภายหลังได้เสมอ (FR-PDPA-02/03; ถอนแล้วลบใน 72 ชม. — รายละเอียดระดับทดสอบ)

### การทำข้อมูลนิรนาม (Data Anonymization — รายละเอียดระดับทดสอบ)

- ระบบล้างข้อมูล EXIF GPS, รุ่นสมาร์ตโฟน และ Metadata ระบุพิกัดหรือตัวตนทั้งหมดก่อนเข้าฐานข้อมูล
- รูปทุกรูปในฝั่งวิจัยและพัฒนาจะไม่เชื่อมต่อกลับไปยังตัวบุคคล

### การถอนความยินยอม (Consent Revocation — Document FR-PDPA-01 AC-3)

- ผู้ใช้สามารถกดถอนความยินยอมของงานวิจัยจากหน้าจอตั้งค่า
- การกดยกเลิก ส่งผลให้ระบบล้างข้อมูลรูปภาพของผู้ใช้ท่านนั้นๆ ออกจาก Research Dataset ภายใน 72 ชม.

### นโยบายการเก็บข้อมูล (Data Retention — RC-PDPA-04 deferred Phase 2; Cron รายวัน 02:00 น.)

- ผลสแกนที่ได้รับความยินยอม (System consent) เก็บ **1 ปี** แล้วลบอัตโนมัติ (Auto-delete ผ่าน Cron Job รายวัน); กรณีถอน consent ลบใน 72 ชม.
- Audit Logs ไม่ลบ (เก็บไว้เพื่อ Compliance)

### กรณีวิเคราะห์ไม่ครบ (canonical: Document FR-ANALYSIS-03 AC-4 fallback; เดิมเรียก NFR-11 wiki-local — ยกเลิกเลขนี้แล้ว)

- ระบบ shall ไม่สรุปว่าภาพปลอดภัยเมื่อวิเคราะห์ไม่ครบ — เมื่อ Reverse Search ล้มเหลว/ยังไม่ตั้งค่า ให้ตั้ง `source_status = "unavailable"` แจ้งผู้ใช้ว่าฟังก์ชันค้นหาแหล่งที่มายังไม่พร้อมใช้งาน และคำนวณคะแนนรวมจากมิติที่สำเร็จเท่านั้น (มติ DOC-01: ไม่ใช้ค่ากลางปลอม)

---

## ความสามารถในการใช้งาน (canonical: Document NFR-06)

| ข้อกำหนด | เป้าหมาย (ตาม Document NFR-06) |
| :--- | :--- |
| ความสามารถในการอธิบายผล Heatmap | >= 80% (n=100) เข้าใจบริเวณต้องสงสัยโดยไม่มีพื้นฐานเทคนิค (UAT protocol + rubric 3 ข้อ: ระบุบริเวณ/อธิบายเหตุผล/ตัดสินใจต่อได้; สุ่มตัวอย่าง) |
| ความพึงพอใจโดยรวมของผู้ใช้ (Likert 1-5) | ระดับคะแนน Mean >= 4.00 ("Good" ขึ้นไป) |

---

## ประสิทธิภาพแคช (canonical: Document NFR-07 — Cache Hit Rate ≥ 40%)

- Redis hit ≤3s (P95), hit-rate ≥40%/สัปดาห์ (alert เมื่อ <35%)
- กลยุทธ์เมื่อต่ำกว่าเป้าหมาย (4 ขั้นตาม Document NFR-07 AC-2): เพิ่ม TTL 60–90 วันสำหรับภาพไวรัล/เสี่ยงสูง, Auto-Scaling AI Workers, Graceful Degradation, Monitoring Alert

---

## ความเข้ากันได้ / การบำรุงรักษา (canonical: Document NFR-08/NFR-09)

- **NFR-08 (Compatibility):** key flows (สมัคร → สแกน → ดูผล) ผ่าน 100% บน Android 10–15 (API 29–35) ผ่าน emulator/device farm บน CI อย่างน้อยเวอร์ชัน 10/12/14/15; Mobile เรียก backend ผ่าน versioned REST (OpenAPI) JSON — SHA-256 ของไฟล์ round-trip ตรงต้นฉบับ 100% และ response ตรง OpenAPI schema (v1 Android เท่านั้น — CON-MOB-01)
- **NFR-09 (Maintainability):** branch coverage ≥80% ทั้ง backend (`pytest --cov`) และ mobile (`flutter test --coverage`) วัดบน CI ทุก PR (ต่ำกว่าเกณฑ์ merge ไม่ได้); static analysis clean (backend: ruff + mypy; mobile: `flutter analyze`) — 0 errors และ warning ใหม่เป็น 0 ก่อน merge; แยก AI Inference Service อิสระ (CON-ARCH-01)

## หน้าที่เกี่ยวข้อง

- [[requirements/objectives-kpis]]
- [[requirements/functional-requirements]]
- [[architecture/system-architecture]]
- [[architecture/database-schema]]
- [[architecture/backend-api]]
