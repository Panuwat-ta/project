---
title: "ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements)"
category: requirements
tags: [NFR, performance, security, PDPA, availability, privacy, HTTPS, JWT]
sources: [doc/srs.md, design/architecture.md, doc/objective.md]
updated: 2026-08-02
---

# ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements)

ข้อกำหนดด้านประสิทธิภาพ, ความปลอดภัย, ความเป็นส่วนตัว, และกฎระเบียบต่างๆ

---

## ประสิทธิภาพ (Performance)

| ข้อกำหนด | เป้าหมาย |
| :--- | :--- |
| ความเร็วตอบสนอง — แบบ Cache Hit | <= 3 วินาที (End-to-End) |
| ความเร็วตอบสนอง — แบบ Full Inference (Cache Miss) | <= 15 วินาทีต่อภาพ |
| System Availability (API + AI Inference) | Uptime >= 99.5% ในช่วงทดสอบ |

**หมายเหตุ:**
- เป้าหมาย Cache Hit 3 วินาที คิดจาก Redis Lookup + PostgreSQL Fetch โดยไม่ต้องมี AI Inference
- เป้าหมาย Full Inference 15 วินาที ครอบคลุมถึง: EXIF + OCR + ตรวจสอบผ่าน API + AI Inference + ผลิต Heatmap + จัดเก็บผลลัพธ์
- ค่าที่ระบุเป็นเป้าหมายสำหรับการทำ Testing Phase ส่วนระดับ SLA ใน Production สามารถระบุเพิ่มเติมได้ภายหลัง

---

## ความแม่นยำของ AI (AI Model Accuracy)

| ตัวชี้วัด | เป้าหมาย |
| :--- | :--- |
| ความแม่นยำ (Accuracy) การตรวจจับภาพตัดต่อ | >= 85% บน Test Set |
| ค่า F1-Score การตรวจจับภาพตัดต่อ | >= 85% บน Test Set |
| ความแม่นยำ (Accuracy) การคัดกรอง AI-Generated | >= 85% บน Test Set |
| ค่า F1-Score การคัดกรอง AI-Generated | >= 85% บน Test Set |

---

## ความปลอดภัย (Security)

### Transport Security
- ทุกช่องทางการเชื่อมต่อระหว่าง Mobile App และ Server ใช้โปรโตคอล **HTTPS/TLS Encryption**
- ไม่อนุญาตให้มีการส่งข้อมูลรูปภาพ หรือ รหัสผ่านแบบ Plaintext เด็ดขาด

### Authentication และ Authorization
- **JWT (JSON Web Token)** — ออกให้เพื่อรับรองการ Login และบังคับตรวจสอบทุก Endpoint ป้องกันระดับสิทธิ์
- นำ Token ไปเก็บใน **Secure Storage** ของสมาร์ตโฟนผู้ใช้ (ไม่ใช่ Shared Preferences หรือไฟล์ข้อความธรรมดา)
- **RBAC (Role-Based Access Control)** — แยกสิทธิ์ระหว่าง User ธรรมดา และ Admin ป้องกันการละเมิด
- Endpoint ของ Admin ทั้งหมดจะปฏิเสธ Token ผู้ใช้ระดับธรรมดาทันที

### ข้อมูล (Data Security)
- ภาพต้นฉบับจะถูกลบออกจาก Cloud Storage อัตโนมัติหลังจากวิเคราะห์ผลเสร็จ (Minimal Retention เก็บเท่าน้อยสุดที่จำเป็น)
- ใช้ Presigned URL ซึ่งเป็นลิงก์แบบมีอายุจำกัด เพื่อส่งมอบข้อมูลที่เข้ารหัสให้เฉพาะ Client ไม่มีการเปิดเผย Credential พื้นฐานออกไป

---

## กฎหมาย PDPA และความเป็นส่วนตัว

กฎหมายว่าด้วยการคุ้มครองข้อมูลส่วนบุคคลของไทย (PDPA) มีผลบังคับใช้กับโครงการนี้อย่างเคร่งครัด

### Privacy by Design
- ระบบออกแบบมาให้จัดเก็บข้อมูลน้อยที่สุดเท่าที่จำเป็น
- ไม่เก็บข้อมูลอื่นที่ไม่อยู่ในจุดประสงค์

### การจัดการความยินยอม (Consent Management)
มีกระบวนการแสดง Consent ให้ยินยอม 2 ระดับ ตอนที่เปิดแอปพลิเคชันครั้งแรก:
1. **System Consent (บังคับ)** — ต้องยินยอมให้ประมวลผลรูปภาพเพื่อการตรวจสอบ หากไม่ให้ จะไม่สามารถใช้งานระบบได้เลย
2. **Research Consent (ไม่บังคับ/เลือกได้)** — การยินยอมให้เก็บรวบรวมรูปภาพ (แบบนิรนาม) สู่ Dataset งานวิจัย AI สามารถเปิดและปิด (Opt-in / Opt-out) ภายหลังได้เสมอ

### การทำข้อมูลนิรนาม (Data Anonymization)
- ระบบล้างข้อมูล EXIF GPS, รุ่นสมาร์ตโฟน และ Metadata ระบุพิกัดหรือตัวตนทั้งหมดก่อนเข้าฐานข้อมูล
- รูปทุกรูปในฝั่งวิจัยและพัฒนาจะไม่เชื่อมต่อกลับไปยังตัวบุคคล

### การถอนความยินยอม (Consent Revocation)
- ผู้ใช้สามารถกดถอนความยินยอมของงานวิจัยจากหน้าจอตั้งค่า
- การกดยกเลิก ส่งผลให้ระบบล้างข้อมูลรูปภาพของผู้ใช้ท่านนั้นๆ ออกจาก Research Dataset ทันที

---

## ความสามารถในการใช้งาน (Usability)

| ข้อกำหนด | เป้าหมาย |
| :--- | :--- |
| ความสามารถในการอธิบายผล Heatmap | >= 80% ของผู้ใช้งานรวม 100 ท่าน เข้าใจว่าบริเวณไหนในภาพที่ต้องสงสัย (โดยที่ไม่ต้องมีพื้นฐานด้านไอที) |
| ความพึงพอใจโดยรวมของผู้ใช้ (Likert 1-5) | ระดับคะแนน Mean >= 4.00 ("Good" ขึ้นไป) |

---

## การขยายระบบ (Scalability)

- AI Inference Service ออกแบบโครงสร้างให้เป็น Container อิสระ เผื่อรับมือช่วงที่ระบบต้องประมวลผลเยอะจนมีอาการหน่วงได้
- ลดจำนวนการทำงานด้วย Redis Cache เป็นส่วนเสริมเพื่อตอบคำถามโดยไม่ต้องรัน AI (Graceful Degradation สำหรับคำถามเดิมๆ ช่วง High Load)

---

## หน้าที่เกี่ยวข้อง

- [[requirements/objectives-kpis]]
- [[requirements/functional-requirements]]
- [[architecture/system-architecture]]
- [[architecture/database-schema]]
- [[architecture/backend-api]]
