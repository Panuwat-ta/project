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
- `doc/objective.md` — วัตถุประสงค์ (OBJ-01 ถึง OBJ-04) และ KPI
- `doc/scop.md` — ขอบเขตโปรเจคและ Work Package
- `design/architecture.md` — สถาปัตยกรรมระบบ, Risk Scoring Pipeline, Tech Stack
- `design/model.md` — การออกแบบโมเดล AI (SegFormer, ELA, Grad-CAM)
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
- `concepts/ela-technique.md`
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

**หมายเหตุ:** เอกสารที่ยังไม่ได้ ingest ครบ: `doc/srs.md` (ฉบับเต็ม), `doc/Use-Case-Diagram.md`, `doc/flowchart.md`, `doc/C1-System-Context-Diagram.md`, `doc/C2-Container-Diagram.md`, `design/design.md`, `design/mobile.md`, `design/training.md`

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

**ประเภทงาน:** รวบรวมเอกสารจากโฟลเดอร์ `doc/`, `design/`, `database/`, และ `server/` เข้าสู่สารบบ Wiki แบบอัตโนมัติ

**รายการไฟล์ที่นำเข้า (พร้อมเพิ่ม Frontmatter):**

- **Requirements:** `srs.md`, `use-case-diagram.md`
- **Architecture:** `c1-system-context-diagram.md`, `c2-container-diagram.md`, `flowchart.md`, `design-overview.md`, `mobile-design.md`, `database-er-diagram.md`
- **Concepts:** `model-training.md`
- **Planning:** `backend-howto.md`

**รายละเอียด:**

- ใช้สคริปต์ `mass_ingest.py` จัดการคัดลอกไฟล์ทั้งหมดและแทรก YAML Frontmatter ด้านบนของไฟล์โดยอัตโนมัติ เพื่อรักษาโครงสร้างเดิมของโปรเจคไว้
- สั่ง Build HTML ใหม่ เพื่อให้เอกสารทั้งหมดเข้าไปอยู่ใน Web Portal (`wed-ScamGuard`) อย่างสมบูรณ์
## [2026-08-06] ingest | /doc/model/model.md
