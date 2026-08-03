---
title: "โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล"
category: architecture
tags: [PostgreSQL, Redis, cache, cloud-storage, schema, ACID]
sources: [design/architecture.md, design/server.md]
updated: 2026-08-02
---

# โครงสร้างฐานข้อมูลและการจัดเก็บข้อมูล

ระบบใช้ Storage 3 ประเภทร่วมกัน: PostgreSQL สำหรับข้อมูลเชิงสัมพันธ์, Redis สำหรับ Cache และ Cloud Object Storage สำหรับไฟล์

---

## PostgreSQL — ฐานข้อมูลหลัก

**หน้าที่:** เก็บข้อมูลเชิงสัมพันธ์ที่มีโครงสร้างทั้งหมดด้วย ACID Transaction

### ตารางหลัก

| ตาราง | คำอธิบาย |
| :--- | :--- |
| `users` | บัญชีผู้ใช้, Role (user/admin), สถานะ Consent, เวลาสมัคร |
| `scans` | แต่ละ Scan: อ้างอิงรูปภาพ, Risk Score, คะแนนแต่ละชั้น, สถานะ, เวลาสร้าง |
| `scan_results` | ผลลัพธ์ละเอียดต่อ Scan: Mask URL, Heatmap URL, Keywords, Source URLs |
| `reports` | รายงาน Scam จากผู้ใช้: Image ID, Reporter ID, สถานะการตรวจสอบของ Admin |
| `model_versions` | Registry โมเดลที่ Deploy แล้วพร้อม Timestamp |
| `audit_log` | บันทึก Append-only ของ Admin Actions ทั้งหมด (Deploy โมเดล, ตัดสิน Report) |

### Field ที่เกี่ยวกับ PDPA

ตาราง `users` มี:
- `consent_analysis` — ยินยอมให้ประมวลผลรูปภาพ (จำเป็น ถ้าไม่ยินยอมใช้แอปไม่ได้)
- `consent_research` — ยินยอมให้นำรูปภาพไป Train AI (ไม่บังคับ ถอนได้)
- `consent_revoked_at` — Timestamp ถ้าผู้ใช้ถอนยินยอมการวิจัย

---

## Redis — Cache Store

**หน้าที่:** ค้นหาภาพที่เคยวิเคราะห์แล้วด้วยความเร็วสูง เพื่อหลีกเลี่ยงการรัน AI ซ้ำ

### การทำงาน

1. เมื่อรับรูปภาพ API คำนวณ **Perceptual Hash (pHash)** ของรูป
2. ใช้ Hash นั้นเป็น Key ใน Redis
3. **Cache Hit** — พบ Hash ใน Redis → ดึงผลลัพธ์เต็มจาก PostgreSQL → ส่งคืนทันที (เป้าหมาย < 3 วินาที)
4. **Cache Miss** — ไม่พบ Hash → รัน Multi-layer Pipeline ครบ → เก็บใน PostgreSQL → เขียน Hash ลง Redis

### Cache Invalidation

- Redis Key หมดอายุตาม TTL ที่ตั้งไว้
- เมื่อ Deploy โมเดลใหม่ (น้ำหนักใหม่) Cache entry เก่าอาจ Stale — Admin สั่ง Cache Invalidation แบบ Forced ได้

---

## Cloud Object Storage

**หน้าที่:** เก็บไฟล์ Binary ที่ไม่เหมาะเก็บในฐานข้อมูล Relational

### โครงสร้างการจัดเก็บ

```
bucket/
  uploads/
    {user_id}/
      {scan_id}/
        original.jpg       # รูปที่อัปโหลดมา (เก็บชั่วคราว)
  heatmaps/
    {scan_id}/
      heatmap.png          # Grad-CAM Heatmap Overlay
  models/
    segformer_v1.0.0.onnx  # Model Weight เวอร์ชัน Production
    segformer_v1.1.0.onnx
```

### Access Control

- Upload Path ใช้ **Presigned URL** — URL จำกัดเวลาต่อ Request ให้ Mobile App อัปโหลดตรงไปยัง Storage โดยไม่เปิดเผย Credential ถาวร
- ไฟล์ Heatmap ผู้ใช้ดาวน์โหลดผ่าน Presigned URL ชั่วคราวเช่นกัน

### การเก็บรักษาข้อมูล

- รูปต้นฉบับที่อัปโหลด **ถูกลบออกจาก Storage** เมื่อวิเคราะห์เสร็จ (ตาม PDPA: เก็บน้อยที่สุด)
- ไฟล์ Heatmap เก็บไว้เชื่อมกับ Scan Record เพื่อแสดงในประวัติสแกน
- ถ้าผู้ใช้ถอนยินยอมการวิจัย รูปภาพของพวกเขาถูกลบออกจาก Research Dataset

---

## ประเด็นสำคัญ

- PostgreSQL คือ Source of Truth สำหรับข้อมูลที่มีโครงสร้างทั้งหมด
- Redis คือ Performance Optimization ไม่ใช่ Data Store — ล้างและสร้างใหม่ได้
- Cloud Storage รับผิดชอบไฟล์ Binary ทั้งหมด ฐานข้อมูล Relational เก็บแค่ Path/URL
- PDPA Compliance บังคับที่ระดับ Storage: เก็บน้อยที่สุด, ต้องยินยอมชัดเจน, ถอนได้

---

## หน้าที่เกี่ยวข้อง

- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
- [[architecture/system-architecture]]
- [[requirements/non-functional-requirements]]
- [[concepts/risk-scoring]]
