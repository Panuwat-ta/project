---
title: "การเชื่อมต่อบริการภายนอก (External Integrations)"
category: architecture
tags: [Google-Vision-API, FCM, Firebase, reverse-image-search, push-notification]
sources: [design/architecture.md, doc/C1-System-Context-Diagram.md]
updated: 2026-08-02
---

# การเชื่อมต่อบริการภายนอก (External Integrations)

บริการภายนอก 2 รายการที่เชื่อมต่อในระบบ ทั้งคู่เรียกผ่าน API Application เท่านั้น ไม่ใช่จาก Client โดยตรง

---

## Google Vision API — Reverse Image Search

**ผู้ให้บริการ:** Google Cloud Vision API (มี Bing Visual Search เป็น Alternative)

**หน้าที่:** ชั้น Source Verification ของ [[concepts/multi-layer-analysis|การวิเคราะห์หลายชั้น]] ตรวจสอบว่ารูปภาพที่อัปโหลดปรากฏในอินเทอร์เน็ตที่อื่นหรือไม่

**การทำงาน:**
1. API Application ส่งรูปภาพ Binary หรือ URL ไปยัง Google Vision API
2. Google Vision ส่งคืน URL ของหน้าเว็บที่พบรูปคล้ายกัน
3. ระบบนับ Domain ที่ไม่ซ้ำกัน
4. >= 3 Domain → ความเสี่ยงแหล่งที่มาสูง
5. <= 1 Domain → ความเสี่ยงต่ำ

**มีส่วนใน:** คะแนน S_source (30% ของ Risk Score รวม)

**กรณี Failure:** ถ้า External API Timeout หรือ Error ระบบจะใช้คะแนน S_source กลางและระบุว่า "Source Verification ไม่พร้อมใช้งาน" ใน Response

---

## Firebase Cloud Messaging (FCM)

**ผู้ให้บริการ:** Google Firebase

**หน้าที่:** Push Notification สำหรับการวิเคราะห์แบบ Asynchronous

**การทำงาน:**
- การวิเคราะห์เต็มรูปแบบ (Cache Miss) ใช้เวลาสูงสุด 15 วินาที
- แทนที่จะ Hold HTTP Connection ไว้ 15 วินาที Mobile App รับ FCM Push Notification เมื่อผลลัพธ์พร้อม
- Notification Payload มี Scan ID และ Risk Grade (Low/Medium/High)
- Mobile App ดึงผลลัพธ์เต็มจาก API ต่อจาก Notification

**เหตุผลที่เลือก FCM:** ฟรีสำหรับ Volume มาตรฐาน, เสถียรบน Android, ไม่ต้องบริหาร Infrastructure

---

## Integration ที่วางแผนในอนาคต

| บริการ | หน้าที่ | สถานะ |
| :--- | :--- | :--- |
| Bing Visual Search | ทางเลือกสำรองสำหรับ Reverse Image Search | วางแผนแล้ว (Fallback) |
| SynthID (Google DeepMind) | ตรวจจับภาพ AI ผ่าน Watermark | กล่าวถึงใน README แต่ยังไม่ได้ออกแบบ |
| Gemini (Google AI) | วิเคราะห์บริบทภาพด้วย LLM | กล่าวถึงใน README แต่ยังไม่ได้ออกแบบ |

> [!NOTE]
> SynthID และ Gemini ถูกอ้างถึงใน README ภายใต้ "เทคโนโลยีระดับสูง" สำหรับ Visual Anomaly Detection แต่การออกแบบ Integration ยังไม่มีเอกสาร ให้ ingest เอกสารที่เกี่ยวข้องเมื่อมีความคืบหน้า

---

## ประเด็นสำคัญ

- ทั้งสองบริการเรียกผ่าน API Application เท่านั้น Client ไม่เรียก External API โดยตรง
- ทั้งคู่มี Fallback/Partial-failure Handling เพื่อป้องกันไม่ให้ Outage ของบริการภายนอกบล็อกการสแกนทั้งหมด
- Google Vision API คือบริการภายนอกเพียงรายการเดียวในการออกแบบปัจจุบันที่มีค่าใช้จ่าย

---

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[architecture/backend-api]]
- [[architecture/system-architecture]]
