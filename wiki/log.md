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
