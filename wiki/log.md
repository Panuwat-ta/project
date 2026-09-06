---
title: "บันทึกการดำเนินงาน Wiki — โปรเจค Scam Image Detection"
---

# บันทึกการดำเนินงาน Wiki

บันทึกตามลำดับเวลาของทุกการดำเนินงานใน wiki แบบ append-only ห้ามลบหรือแก้ไข entry เก่า

```bash
# ดู 5 entry ล่าสุด:
grep "^## \[" wiki/log.md | tail -5
```

---

## [2026-08-02] init | สร้าง Wiki ครั้งแรกจากเอกสารต้นฉบับทั้งหมด

**ประเภทงาน:** สร้าง wiki ครั้งแรก — นำเข้าเอกสารต้นฉบับที่มีอยู่ทั้งหมด

**เอกสารที่ประมวลผล:**

- `README.md` — ภาพรวมโปรเจค, ทีม, ลิงก์ workspace
- `Document/objective.md` — วัตถุประสงค์ (OBJ-01 ถึง OBJ-04) และ KPI
- `Document/scop.md` — ขอบเขตโปรเจคและ Work Package
- `design/architecture.md` — สถาปัตยกรรมระบบ, Risk Scoring Pipeline, Tech Stack
- `design/model.md` — การออกแบบโมเดล AI (SegFormer, Semantic Segmentation, Heatmap)
- `design/server.md` — โครงสร้าง Backend FastAPI และ Database

**หน้าที่สร้าง:**

- `AGENTS.md` — schema และคู่มือการดำเนินงานสำหรับ LLM
- `index.md` — สารบัญทุกหน้า
- `log.md` — ไฟล์นี้
- `howto.md` — คู่มือการใช้งาน wiki
- `overview.md` — ภาพรวมโปรเจค
- `concepts/multi-layer-analysis.md`
- `concepts/risk-scoring.md`
- `concepts/explainable-ai.md`
- `concepts/ai-model-segformer.md`
- `concepts/semantic-segmentation.md`
- `architecture/system-architecture.md`
- `architecture/mobile-app.md`
- `architecture/backend-api.md`
- `architecture/ai-inference-service.md`
- `architecture/database-schema.md`
- `architecture/external-integrations.md`
- `entities/actors.md`
- `entities/tech-stack.md`
- `decisions/technology-choices.md`
- `requirements/objectives-kpis.md`
- `requirements/functional-requirements.md`
- `requirements/non-functional-requirements.md`
- `planning/project-scope.md`
- `planning/team.md`

**หมายเหตุ:** เอกสารที่ยังไม่ได้ ingest ครบ: `Document/srs.md` (ฉบับเต็ม), `Document/Use-Case-Diagram.md`, `Document/flowchart.md`, `Document/C1-System-Context-Diagram.md`, `Document/C2-Container-Diagram.md`, `design/design.md`, `design/mobile.md`, `design/training.md`

---

## [2026-08-02] update | แปลทุกหน้าเป็นภาษาไทย

**ประเภทงาน:** แปลเนื้อหาทั้งหมดเป็นภาษาไทย คงคำศัพท์เทคนิคภาษาอังกฤษตามมาตรฐานวิชาชีพ

---

## [2026-08-04] update | Phase 4 OCR Integration & Qwen2.5-VL Fix

**ประเภทงาน:** ติดตั้งและปรับแต่งโมเดล Surya OCR 2 (GGUF)

**รายละเอียด:**

- ปรับปรุงไฟล์ `inference_service.py` ให้โหลด `surya-2.gguf` ผ่าน `llama-cpp-python`
- อัปเดต `scan_service.py` เพื่อนำ `ocr_text` ที่อ่านได้มาคิดคะแนน `text_score` ร่วมกับ Scam Keywords (เช่น ด่วน, โบนัส, ลงทุน)
- **Problem Solving:** แก้บั๊ก Context Memory ของ Qwen2-VL โดยการเปลี่ยน Chat Handler ไปใช้ `Qwen25VLChatHandler` แทน `Llava15ChatHandler` และขยาย `n_ctx=8192` ทำให้สามารถประมวลผลรูปภาพความละเอียดสูงได้สมบูรณ์
- **GPU Optimization:** แนะนำและวางแนวทางการติดตั้ง `cuda-toolkit` OS-level เพื่อนำเข้าไดรเวอร์ `libcudart` ให้ `llama-cpp-python` รันบน VRAM (RTX 3050) ได้ 100% (n_gpu_layers=-1)

---

## [2026-08-04] mass_ingest | ย้ายเอกสารต้นฉบับเข้า Wiki

**ประเภทงาน:** รวบรวมเอกสารจากโฟลเดอร์ `Document/`, `design/`, `database/`, และ `server/` เข้าสู่สารบบ Wiki แบบอัตโนมัติ

**รายการไฟล์ที่นำเข้า (พร้อมเพิ่ม Frontmatter):**

- **Requirements:** `srs.md`, `use-case-diagram.md`
- **Architecture:** `c1-system-context-diagram.md`, `c2-container-diagram.md`, `flowchart.md`, `design-overview.md`, `mobile-design.md`, `database-er-diagram.md`
- **Concepts:** `model-training.md`
- **Planning:** `backend-howto.md`

**รายละเอียด:**

- ใช้สคริปต์ `mass_ingest.py` จัดการคัดลอกไฟล์ทั้งหมดและแทรก YAML Frontmatter ด้านบนของไฟล์โดยอัตโนมัติ เพื่อรักษาโครงสร้างเดิมของโปรเจคไว้
- สั่ง Build HTML ใหม่ เพื่อให้เอกสารทั้งหมดเข้าไปอยู่ใน Web Portal (`web-ScamGuard`) อย่างสมบูรณ์
## [2026-08-06] ingest | /Document/model/model.md

---

## [2026-09-06] sync | อัปเดต Wiki ให้สอดคล้องกับ Document, design และระบบจริง

**ประเภทงาน:** ซิงค์และเติมเต็มเอกสาร Wiki จาก Document, design และโครงสร้างระบบจริงล่าสุด

**หน้าที่สร้างใหม่:**
- `architecture/admin-portal.md` — สถาปัตยกรรมและการออกแบบ Admin Portal (React/Vite, UI Design System, Model Registry, Telemetry) จาก `design/admin.md` และ `Document/admin/admin.md`
- `architecture/database-migrations.md` — คู่มือและขั้นตอนการย้ายฐานข้อมูล (Database Migrations) ด้วย Alembic จาก `Document/database/alembic.md`
- `concepts/mmsegmentation.md` — สถาปัตยกรรมโมดูลาร์ MMSegmentation (Backbone MiT, Decode Head, Training Loss) จาก `Document/model/mmsegmentation.md`
- `requirements/traceability-matrix.md` — เมทริกซ์การสืบย้อนความต้องการ (Requirement Traceability Matrix - RTM) เชื่อมโยง ST -> OBJ -> SC -> RC -> FR/NFR จาก `Document/docs/06_Requirement_Traceability.md` และ `07_Appendix_A_Full_Traceability_Matrix.md`
- `planning/task-tracking.md` — การติดตามงานและการบริหารโครงการผ่านกระดาน Jira SCM และสถานะรายเฟส จาก `Document/jira/Task-Tracking.md` และ `Document/jira/to-do-list.md`

**หน้าที่ปรับปรุง:**
- `architecture/database-er-diagram.md` — อัปเดต Mermaid ER Diagram เพิ่มตาราง `admins` แยกเดี่ยว, เพิ่มฟิลด์ `title` และ `progress` ใน `scans`, ปรับ Foreign Key ให้ชี้ไปยัง `admins` ตาม `database/ER_Diagram.md` ล่าสุด
- `architecture/database-schema.md` — อัปเดตคำอธิบายตารางหลักใน PostgreSQL ให้มี `admins`, `scam_reports`, `consent_logs` และเชื่อมโยงหน้ารายละเอียด
- `index.md` — เพิ่มรายการหน้าใหม่ทั้งหมด 5 หน้าลงในสารบัญครบทุกหมวดหมู่

**ผลการตรวจสอบ:**
- สถาปัตยกรรมครอบคลุมครบทั้ง 4 คอนเทนเนอร์หลัก (Mobile App, Backend API, AI Inference, Admin Portal)
- โครงสร้างฐานข้อมูลใน Wiki สอดคล้องกับ PostgreSQL และ `database/ER_Diagram.md` ล่าสุด
- เอกสารทั้งหมดไม่มีสัญลักษณ์ Emoji และรันคอมไพล์เว็บ `web-ScamGuard` ผ่านสมบูรณ์

