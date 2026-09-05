---
title: "การติดตามงานและการบริหารโครงการ (Task Tracking & Jira)"
category: planning
tags: [planning, jira, task-tracking, scrum, kanban, project-management]
sources: [Document/jira/Task-Tracking.md, Document/jira/to-do-list.md]
updated: 2026-09-06
---

# การติดตามงานและการบริหารโครงการ (Task Tracking & Jira)

โครงสร้างการติดตามความคืบหน้าของงาน พัฒนาการของระบบ และการบริหารโครงการ ScamGuard ผ่านกระดาน Jira และรายงานสถานะตาม Work Packages

---

## 1. ข้อมูลโครงการและบอร์ดติดตามงาน (Jira Board)

ทีมพัฒนาใช้ซอฟต์แวร์ Jira ในการบริหารจัดการและติดตามงานตามแนวทาง Agile/Scrum:

- **รหัสโครงการ (Project Key):** SCM
- **กระดานติดตามงาน (Board):** ScamGuard Board
- **สถานะการดำเนินงาน (Workflow Statuses):**
  1. **To Do:** งานที่ผ่านการวิเคราะห์และรอเริ่มดำเนินการ
  2. **In Progress:** งานที่อยู่ระหว่างการพัฒนาหรือทดสอบในเครื่องผู้พัฒนา
  3. **In Review:** งานที่เสร็จสิ้นแล้วและอยู่ระหว่างการตรวจสอบโค้ด (Code Review) หรือการทดสอบเทียบกับเกณฑ์ยอมรับ (Acceptance Criteria)
  4. **Done:** งานที่ผ่านการทดสอบ ผ่านการ Review และรวมเข้าสู่กิ่งหลัก (Main Branch) เรียบร้อยแล้ว

---

## 2. สถานะความคืบหน้าภาพรวมรายเฟส (Phase Progress)

| เฟสการทำงาน | รายละเอียดงาน | สถานะ | ความคืบหน้า |
| :--- | :--- | :--- | :--- |
| **เฟส 1: ข้อกำหนดและการวางแผน** | รวบรวม Requirement Candidates (RC), วิเคราะห์ SRS, กำหนด KPI และขอบเขตงาน | เสร็จสิ้น | 100% |
| **เฟส 2: การออกแบบระบบและสถาปัตยกรรม** | ออกแบบ C1-C4 Diagrams, ER Diagram, UI/UX บน Figma และ Design System | เสร็จสิ้น | 100% |
| **เฟส 3: การพัฒนาส่วนประกอบหลัก** | พัฒนา Mobile App, FastAPI Backend, AI SegFormer Model, Surya OCR และ Admin Portal | กำลังดำเนินการ | 90% |
| **เฟส 4: การทดสอบและการผสานระบบ** | Automated Test Suites (Unit/Integration/E2E), Performance Load Test และ NFR Validation | กำลังดำเนินการ | 85% |
| **เฟส 5: การส่งมอบและเอกสารสมบูรณ์** | รวบรวมเอกสารคู่มือ บันทึกการดำเนินงาน และรายงานผลการตรวจรับโครงงานวิศวกรรม | กำลังดำเนินการ | 80% |

---

## 3. รายการงานสำคัญแยกตามคอมโพเนนต์ (Key Component Work Packages)

### 3.1 Mobile Application (Flutter)
- พัฒนาโครงสร้าง Clean Architecture (Presentation, Domain, Data) พร้อม BLoC State Management
- ปรับปรุง UI รองรับ Dark Mode First และ Light Mode ตามมาตรฐาน WCAG AA
- เชื่อมต่อ RESTful API เต็มรูปแบบกับระบบหลังบ้าน (นำ Mock Repositories ออก)
- เพิ่มระบบแคชและประวัติการสแกนย้อนหลัง (Recent History, Thumbnails, Tap Navigation)

### 3.2 Backend API & Database (FastAPI & PostgreSQL)
- ออกแบบ RESTful API Endpoints สำหรับ Authentication, Scan Processing และ Admin Operations
- วางระบบ Caching บน Redis ด้วย Perceptual Hash (pHash) ตอบกลับในเวลาน้อยกว่า 3 วินาที
- แยกสคีมาตาราง `admins` ออกจาก `users` เพื่อความปลอดภัยขั้นสูงสุด
- ติดตั้งระบบ Database Migration ด้วย Alembic เพื่อควบคุมการเปลี่ยนแปลงของสคีมา

### 3.3 AI Inference Engine & Pipelines
- พัฒนาและส่งออกโมเดล SegFormer (MiT-B0 ถึง MiT-B2) ในรูปแบบ ONNX Runtime
- ใช้อัลกอริทึม Overlapping Tiling Inference ป้องกันรอยต่อของภาพขนาดใหญ่
- ติดตั้ง Surya OCR 2 (GGUF) สำหรับการสกัดข้อความภาษาไทยและอังกฤษ
- ปรับแต่ง XAI Pipeline ร่วมกับ Qwen2.5 สำหรับสร้างคำอธิบายความผิดปกติ

### 3.4 Admin Portal (React / Vite)
- พัฒนา Web Console สำหรับผู้ดูแลระบบ เชื่อมต่อ API จริงและฐานข้อมูล PostgreSQL
- แสดงสถิติและสถานะระบบแบบ Real-time ด้วย WebSocket Telemetry
- ระบบ AI Model Registry ควบคุมการ Deploy/Rollback เวอร์ชันโมเดลพร้อม Row Locking
- ระบบจัดการและตรวจสอบข้อร้องเรียน (Moderation Queue) เพื่อคัดเลือกภาพเข้า Dataset

---

## 4. ประเด็นสำคัญ

- งานทั้งหมดถูกแบ่งย่อยและมี Traceability เชื่อมโยงกลับไปยังข้อกำหนดใน [[requirements/traceability-matrix|Traceability Matrix]] เสมอ
- การเปลี่ยนแปลงในแต่ละคอมโพเนนต์จะถูกบันทึกลงใน Git และบันทึกประวัติการพัฒนาใน `.agents/log.md`
- ความคืบหน้าทางเทคนิคในปัจจุบันมุ่งเน้นการเสริมความแข็งแกร่ง (Hardening) การทดสอบระบบอัตโนมัติ และความปลอดภัย

---

## หน้าที่เกี่ยวข้อง

- [[planning/project-scope|ขอบเขตโครงการ (Project Scope)]]
- [[planning/team|ทีมพัฒนาและที่ปรึกษา]]
- [[requirements/traceability-matrix|เมทริกซ์การสืบย้อนความต้องการ (Traceability Matrix)]]
- [[architecture/system-architecture|สถาปัตยกรรมระบบโดยรวม]]
