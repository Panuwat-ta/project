---
title: "ผู้ใช้ระบบ (Actors)"
category: entities
tags: [users, admin, researcher, roles, RBAC]
sources: [design/architecture.md, doc/srs.md, doc/Use-Case-Diagram.md]
updated: 2026-08-02
---

# ผู้ใช้ระบบ (Actors)

บุคคลและบทบาทที่มีชื่อซึ่งใช้งานระบบ Scam Image Detection

---

## ผู้ใช้ทั่วไป (General User)

**ผู้คือ:** ประชาชนทั่วไปที่ต้องการตรวจสอบว่ารูปภาพน่าจะถูกตัดต่อหรือใช้ในการหลอกลวงหรือไม่

**ส่วนติดต่อผู้ใช้ (Interface):** Flutter Mobile App (Android)

**Use Cases ทั่วไป:**

- ได้รับสลิปโอนเงินที่น่าสงสัยและต้องการตรวจสอบ
- กำลังจะเชื่อใจรูปโปรไฟล์จากคนแปลกหน้าบนโลกออนไลน์
- พบรูปภาพโปรโมทที่น่าสงสัยซึ่งรับประกันผลตอบแทนสูง
- ต้องการตรวจสอบรูปภาพก่อนแชร์ต่อ

**สิ่งที่ทำได้:**

- สมัครสมาชิกและเข้าสู่ระบบ (Email/Password หรือ Google OAuth)
- อัปโหลดหรือถ่ายรูปเพื่อตรวจสอบ
- ตัดภาพ (Crop) ก่อนส่งเพื่อโฟกัสบริเวณใดบริเวณหนึ่ง
- ดู Risk Score และ Heatmap overlay
- ดูประวัติการสแกน
- ส่งรายงานแจ้งว่ารูปนี้เป็น Scam ที่ยืนยันแล้ว
- จัดการตั้งค่ายินยอม PDPA (รวมถึงถอนยินยอมการวิจัย)

**สิ่งที่ทำไม่ได้:**

- เข้าถึง Admin Dashboard หรือเครื่องมือจัดการโมเดล
- ดูการสแกนของผู้ใช้อื่น
- อนุมัติหรือปฏิเสธ Scam Report

---

## แอดมิน / นักวิจัย (Admin / Researcher)

**ผู้คือ:** เจ้าหน้าที่ภายใน, นักวิจัย AI หรือทีมสนับสนุนของโปรเจค

**ส่วนติดต่อผู้ใช้ (Interface):** React.js Admin Web Portal

**สิ่งที่ทำได้:**

- ดูสถิติทั้งระบบ: จำนวนสแกนรวม, Accuracy Metrics, ปริมาณ Traffic
- ตรวจสอบคิว Scam Report จากผู้ใช้ และทำเครื่องหมายยืนยันหรือเพิกเฉย
- นำรูป Scam ที่ยืนยันแล้วไปสร้างและคัดกรอง Training Dataset
- อัปโหลด Model Weight ไฟล์ใหม่และสั่ง Deploy โมเดล
- จัดการบัญชีผู้ใช้ (CRUD ตามที่สิทธิ์ RBAC อนุญาต)

**หมายเหตุเรื่อง RBAC:** สิทธิ์ Admin บังคับใช้ที่ระดับ API ผ่าน JWT Claims ถึงจะมีคนเข้าถึง URL ของ Admin Portal ได้ แต่ API Endpoint สำหรับ Admin จะปฏิเสธ Token ของผู้ใช้ทั่วไปทั้งหมด

---

## ระบบ (Automated Actor)

ไม่ใช่คน แต่เป็น Actor ที่ควรบันทึกไว้:

- **Redis Cache** — ส่งคืนผลลัพธ์จาก Cache อัตโนมัติ โดยไม่มีคนเข้ามาเกี่ยวข้อง
- **FCM** — ส่ง Push Notification อัตโนมัติเมื่องานสแกนเสร็จสิ้น
- **Scheduled Model Retraining** — ระบบอัตโนมัติที่วางแผนไว้ในอนาคต เมื่อมี Scam Report ที่ยืนยันแล้ว ระบบจะกระตุ้นให้เทรนโมเดลใหม่แบบ Incremental

---

## หน้าที่เกี่ยวข้อง

- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[requirements/functional-requirements]]
- [[requirements/non-functional-requirements]]
- [[planning/team]]
