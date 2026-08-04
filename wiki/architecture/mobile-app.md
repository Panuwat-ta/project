---
title: "สถาปัตยกรรม Mobile App"
category: architecture
tags: [Flutter, BLoC, Clean-Architecture, MVVM, Android, image-upload]
sources: [design/architecture.md, design/mobile.md, design/design.md]
updated: 2026-08-02
---

# สถาปัตยกรรม Mobile App

แอปพลิเคชัน Android ที่พัฒนาด้วย Flutter สำหรับผู้ใช้ทั่วไปในการส่งรูปภาพและรับรายงานความเสี่ยง

---

## เทคโนโลยีที่ใช้

- **Framework:** Flutter (Dart)
- **Platform:** Android (หลัก) — iOS ไม่อยู่ในขอบเขต v1
- **รูปแบบสถาปัตยกรรม:** Clean Architecture + MVVM
- **State Management:** BLoC (Business Logic Component)
- **HTTP Client:** Dio (พร้อม Secure Storage สำหรับ JWT Token)

---

## ชั้นของ Clean Architecture

| ชั้น | หน้าที่ |
| :--- | :--- |
| Presentation Layer | Flutter Widgets, หน้าจอต่างๆ, สถานะ UI |
| Domain Layer | Use Case, Business Rules, Entities |
| Data Layer | API Client, Local Storage, Repository Implementation |

การแบ่งชั้นนี้ทำให้ UI ไม่ขึ้นตรงต่อ Networking หรือ Business Logic โดยตรง ทำให้ทดสอบและบำรุงรักษาได้ง่าย

---

## หน้าจอหลัก / User Flow

1. **หน้าจอ Authentication** — สมัครสมาชิก, Login (email/password + Google OAuth)
2. **หน้าจอรับรูปภาพ** — เลือกจาก Gallery หรือถ่ายด้วยกล้อง พร้อม Image Cropper เพื่อโฟกัสบริเวณที่ต้องการตรวจก่อนส่ง
3. **หน้าจอรอประมวลผล** — แสดงระหว่าง Pipeline ทำงาน (สูงสุด 15 วินาที หรือเกือบทันทีสำหรับ Cache Hit)
4. **หน้าจอรายงานความเสี่ยง** — แสดง:
   - Weighted Risk Score แบบ color gauge (เขียว / เหลือง / แดง)
   - Grad-CAM Heatmap ซ้อนทับรูป — toggle เปิด/ปิดได้
   - คำหลอกลวงที่พบ (ถ้ามี)
   - ผลการ Reverse Image Search
   - คะแนนแยกตามชั้นการวิเคราะห์
5. **หน้าจอประวัติสแกน** — รายการสแกนก่อนหน้าพร้อม timestamp และคะแนน พร้อมการควบคุม PDPA
6. **หน้าจอรายงาน Scam** — ผู้ใช้แจ้งว่าภาพนี้เป็น Scam จริงเพื่อให้ Admin ตรวจสอบ

---

## ขั้นตอนการอัปโหลดรูปภาพ

```
ผู้ใช้เลือก/ถ่ายรูป
        |
  Image Cropper (ถ้าต้องการ)
        |
  Multipart HTTP POST → API Gateway
        |
  Polling หรือ WebSocket รอผลลัพธ์
  (หรือรับ FCM Push Notification เมื่อ Async Job เสร็จ)
        |
  แสดงหน้าจอรายงานความเสี่ยง
```

---

## ความปลอดภัยใน App

- JWT Token เก็บใน **Secure Storage** (ไม่ใช่ SharedPreferences หรือไฟล์ธรรมดา)
- ไม่เก็บข้อมูลรูปภาพบนอุปกรณ์หลังส่งประมวลผลแล้ว
- แสดงหน้าจอยินยอม PDPA ตอน Launch ครั้งแรก สามารถถอนยินยอมได้ในหน้าตั้งค่า

---

## โครงสร้างโฟลเดอร์ Flutter

```
lib/
  core/           # Config ส่วนกลาง, Theme, Routing, DI
  features/
    auth/         # Login, Register screens + BLoC
    scan/         # อัปโหลดรูป, แสดงผล, ประวัติ
    report/       # ส่งรายงาน Scam
  main.dart
```

> [!NOTE]
> โครงสร้างโฟลเดอร์โดยละเอียดพร้อม Feature subdirectory ทั้งหมดอยู่ใน `design/mobile.md` ซึ่งยังไม่ได้ ingest ครบ

---

## Admin Portal (แยกต่างหาก)

Admin Web Portal เป็น React.js + Tailwind CSS แยกต่างหากสำหรับใช้งานภายใน ไม่ใช่ Mobile App ดู [[architecture/backend-api]] สำหรับ Endpoint ที่ใช้

**ความสามารถของ Admin Portal:**

- Dashboard สถิติระบบและ Accuracy Metrics
- Report Management — ตรวจสอบและยืนยัน/ปฏิเสธรายงาน Scam จากผู้ใช้
- Data Enrichment — รวบรวมรูปภาพ Scam ที่ยืนยันแล้วสำหรับ Training Dataset
- Model Deployment — อัปโหลดและเปิดใช้งาน Model Weight ใหม่

---

## หน้าที่เกี่ยวข้อง

- [[architecture/system-architecture]]
- [[architecture/backend-api]]
- [[concepts/explainable-ai]]
- [[entities/actors]]
- [[requirements/functional-requirements]]
