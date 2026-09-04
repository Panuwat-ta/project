# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users
- General Users: ผู้ใช้งานทั่วไปที่ต้องการตรวจสอบรูปภาพ (เช่น สลิปโอนเงิน, รูปโปรไฟล์, สกรีนช็อตแชท, เอกสาร) เพื่อระบุความเสี่ยงของการหลอกลวง (Scam) ก่อนตัดสินใจเชื่อหรือทำธุรกรรม
- Admins / Researchers: ผู้ดูแลระบบและนักวิจัยที่ต้องการตรวจสอบ ติดตามสถิติภาพรวม จัดการผู้ใช้งาน ตรวจสอบประวัติการสแกน และปรับตั้งค่าโมเดล AI

## Product Purpose
ScamGuard เป็นระบบและแอปพลิเคชันตรวจสอบรูปภาพที่อาจถูกตัดต่อ ดัดแปลง ปลอมแปลง หรือสร้างขึ้นด้วย AI เพื่อนำมาใช้ในการหลอกลวง (Scam Image Detection) โดยใช้การวิเคราะห์หลายชั้น (Multi-layer Analysis) ได้แก่ การตรวจจับข้อความ (OCR), การตรวจสอบแหล่งที่มา (Source Verification) และการตรวจจับความผิดปกติของภาพด้วย AI (Visual Anomaly Detection) พร้อมแสดงผลลัพธ์แบบ Explainable AI ด้วย Heatmap และคำนวณคะแนนความเสี่ยง (Risk Score)

## Positioning
ตรวจจับภาพหลอกลวงในวงกว้าง ไม่จำกัดเฉพาะสลิปโอนเงินธนาคาร แต่ครอบคลุม Romance Scam, ภาพตัดต่อปลอมแปลงตัวตน, สกรีนช็อตที่ดัดแปลงเนื้อหา และภาพสังเคราะห์จาก AI โดยเน้นความโปร่งใสด้วยการแสดง Heatmap ชี้ตำแหน่งผิดปกติบนภาพจริง และประเมินคะแนนความเสี่ยงแบบ Hybrid Worst-Case (Max-Impact & Multi-Factor Breakdown) 3 ระดับ (Low: 0-39, Medium: 40-69, High: 70-100)

## Operating Context
- ผู้ใช้งานทั่วไปใช้งานผ่าน Flutter Mobile App (Android) โดยเลือกรูปภาพจากคลังภาพหรือถ่ายภาพจากกล้อง ส่งตรวจสอบ และรับผลการวิเคราะห์พร้อม Heatmap ซ้อนทับและคำอธิบายจุดน่าสงสัย
- แอดมินและนักวิจัยใช้งานผ่าน Admin Portal (React.js + Tailwind CSS) บนเว็บเบราว์เซอร์ เพื่อดูแดชบอร์ดสถิติ จัดการแบนผู้ใช้งาน และจัดการเวอร์ชันโมเดล AI
- สถาปัตยกรรมระบบทำงานแบบ Cloud-Native ประกอบด้วย FastAPI Orchestrator, AI Inference Service (SegFormer, Surya OCR, ONNX/PyTorch), PostgreSQL, และ Redis สำหรับ Caching ตาม image_hash

## Capabilities and Constraints
- ตรวจจับความผิดปกติของภาพและประเมินระดับความเสี่ยงได้ 3 ระดับ: Low, Medium, High (ไม่มีระดับ Safe)
- ระบบวิเคราะห์ 3 ชั้นอิสระ (0–100% แต่ละชั้น): Textual Analysis (OCR + NLP), Source Verification (Google Vision API), Visual Anomaly Detection (SegFormer AI Heatmap) โดยคำนวณคะแนนภาพรวมด้วยหลักการ Maximum Impact (Worst-Case Dominance) ร่วมกับ Multi-Factor Compounding
- มาตรการความเป็นส่วนตัว (PDPA): ผู้ใช้ต้องให้ความยินยอมก่อนจัดเก็บหรือนำภาพไปใช้ในการปรับปรุงโมเดล โดยสามารถจัดการสิทธิ์และความเป็นส่วนตัวได้
- ห้ามใช้อิโมจิในทุกส่วนติดต่อผู้ใช้ (UI) และข้อความของระบบตามนโยบายของโปรเจกต์
- Mobile App พัฒนาด้วย Flutter (Clean Architecture, BLoC State Management) รองรับ Android
- Admin Portal พัฒนาด้วย React และ Tailwind CSS
- Backend พัฒนาด้วย Python FastAPI เชื่อมต่อไปยัง AI Node

## Brand Commitments
- การออกแบบ UI เน้นความเรียบหรู น่าเชื่อถือ ทันสมัย สื่อถึงความปลอดภัยทางดิจิทัล (Modern, Trustworthy, High-security)
- ห้ามใช้อิโมจิในการสื่อสารทุกรูปแบบ
- การจัดวางและภาษาที่ใช้ใน Mobile App เป็นภาษาไทยเป็นหลัก พร้อมระบุค่าทางเทคนิคเป็นสากล

## Evidence on Hand
- ข้อมูลระบบและสถาปัตยกรรมบันทึกไว้อย่างครบถ้วนใน wiki/ (Architecture, Concepts, Requirements, Entities, Decisions, Planning)
- โค้ดส่วน Mobile App ใน scam_image_mobile/ เชื่อมต่อกับ Backend จริงแล้ว
- โค้ดส่วน Admin Portal ใน admin-portal/ และ API Backend ใน server/
- ผลการทดสอบระบบอัตโนมัติจัดเก็บใน tests_report/

## Product Principles
1. Comprehensive Scam Detection: ตรวจจับภาพหลอกลวงหลากหลายรูปแบบ ไม่จำกัดเฉพาะสลิปธนาคาร
2. Explainable AI: แสดงผลลัพธ์ที่โปร่งใสและเข้าใจง่ายด้วย Heatmap ซ้อนทับจุดดัดแปลง พร้อมแจกแจงผลวิเคราะห์แต่ละชั้น
3. High Trust & Privacy: ปฏิบัติตามมาตรฐาน PDPA จัดเก็บข้อมูลอย่างปลอดภัย ให้ผู้ใช้ควบคุมความยินยอมได้
4. High Performance: ใช้ Redis Caching ด้วย image_hash เพื่อให้ผลการตรวจซ้ำตอบกลับรวดเร็ว (< 3 วินาที)

## Accessibility & Inclusion
- รองรับมาตรฐานความสามารถในการเข้าถึงขั้นพื้นฐานบน Android: Touch Target ขั้นต่ำ 48x48 dp และ Contrast Ratio ที่ชัดเจน
- ขนาดตัวอักษรและข้อความสามารถปรับตามการตั้งค่าของระบบปฏิบัติการ (System font scale) ได้อย่างเหมาะสม
