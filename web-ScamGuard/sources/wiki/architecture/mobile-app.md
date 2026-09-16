---
title: "สถาปัตยกรรม Mobile App"
category: architecture
tags: [Flutter, BLoC, Clean-Architecture, MVVM, Android, image-upload]
sources: [design/architecture.md, design/mobile.md, design/design.md]
updated: 2026-09-16
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

## Routes และ User Flow ที่มีใน code

`app_router.dart` ประกาศ 16 routes (ไม่ใช่ 6 หน้าจอ):

| กลุ่ม | Route |
| :--- | :--- |
| Entry/Auth | `/splash`, `/onboarding`, `/login`, `/register` |
| Main shell | `/main/home`, `/main/history`, `/main/report`, `/main/settings` |
| Settings | `/main/settings/profile`, `/main/settings/privacy` |
| Scan/Result | `/crop`, `/loading`, `/result/:scanId`, `/heatmap/:scanId` |
| Other | `/notifications`, `/detail/:scanId` |

หน้าผลลัพธ์แสดง Overall Risk Score, badge 3 ระดับ (เขียว/amber/แดง), Heatmap, OCR, Source Verification และ Breakdown 3 มิติ Visual/Textual/Source

---

## ขั้นตอนการอัปโหลดรูปภาพ

```
ผู้ใช้เลือกรูปจากคลังภาพ
        |
  Image Cropper (ถ้าต้องการ)
        |
  Multipart HTTP POST → API Gateway
        |
  Polling GET /api/v1/scan/{scan_id} ทุก 3 วินาที
        |
  แสดงหน้าจอรายงานความเสี่ยง
```

---

## ความปลอดภัยใน App

- JWT Token เก็บใน **Secure Storage**
- ไม่เก็บข้อมูลรูปภาพบนอุปกรณ์หลังส่งประมวลผลแล้ว
- Backend บันทึก `system_consent` และ `research_consent` จาก body ของ `POST /api/v1/auth/register`; onboarding เป็นการรับทราบฝั่ง UI ไม่ใช่จุดบันทึก consent ลง server

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
---

## Admin Portal (แยกต่างหาก)

Admin Web Portal เป็น React 19 + Vite 8 + Tailwind CSS v4 แยกต่างหากสำหรับใช้งานภายใน ดู [[architecture/backend-api]] สำหรับ Endpoint ที่ใช้

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
