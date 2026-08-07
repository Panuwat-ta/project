---
title: "วิธีใช้งาน Wiki (How to Use This Wiki)"
category: guide
tags: [howto, guide, workflow, obsidian, LLM]
updated: 2026-08-02
---

# วิธีใช้งาน Wiki

Wiki นี้คือฐานความรู้ถาวรของโปรเจค **Scam Image Detection** ที่ดูแลรักษาโดย LLM Agent  
แนวคิดหลักคือ: **คุณเป็นคนหาข้อมูลและตั้งคำถาม — LLM เป็นคนเขียนและอัปเดต wiki**

---

## โครงสร้างของ Wiki

```
wiki/
  AGENTS.md          <- คู่มือสำหรับ LLM: schema, convention, workflow
  index.md           <- สารบัญรวมทุกหน้า (เริ่มอ่านที่นี่)
  log.md             <- บันทึกการดำเนินงานตามลำดับเวลา
  overview.md        <- ภาพรวมโปรเจคทั้งหมด
  howto.md           <- ไฟล์นี้: คู่มือการใช้งาน

  concepts/          <- แนวคิดและเทคนิค (Semantic Segmentation, SegFormer, XAI, Risk Scoring)
  architecture/      <- การออกแบบระบบ (Mobile, Backend, AI, Database)
  entities/          <- สิ่งที่มีชื่อในระบบ (Actors, Tech Stack)
  decisions/         <- การตัดสินใจเลือกเทคโนโลยีและ tradeoff
  requirements/      <- ความต้องการของระบบ (Objectives, KPIs, FR, NFR)
  planning/          <- ขอบเขตงาน, ทีม, แผนการทำงาน
```

---

## เปิดใช้งานกับ Obsidian

1. เปิด Obsidian
2. เลือก **Open folder as vault**
3. เลือกโฟลเดอร์ `/home/panuwat/project/wiki`
4. ใช้ **Graph view** (ไอคอนกราฟ) เพื่อดูความสัมพันธ์ระหว่างหน้าต่างๆ
5. เริ่มที่ [`index.md`](index.md) เพื่อดูสารบัญทั้งหมด หรือ [`overview.md`](overview.md) เพื่อเข้าใจภาพรวมโปรเจค

---

## 3 วิธีใช้งาน LLM กับ Wiki

### 1. Ingest — เพิ่มเอกสารใหม่เข้า Wiki

เมื่อมีเอกสารใหม่ในโปรเจค (เช่น ไฟล์ใน `doc/` หรือ `design/`) บอก LLM ว่า:

```
"ingest design/training.md เข้า wiki"
```

LLM จะ:

- อ่านเอกสารต้นฉบับ (raw source) โดยไม่แก้ไขต้นฉบับ
- เขียนหรืออัปเดตหน้า wiki ที่เกี่ยวข้อง (อาจกระทบ 5–15 หน้า)
- อัปเดต `index.md`
- บันทึก entry ใหม่ลง `log.md`

**สถานะการย้ายเอกสาร (Ingestion Status): 100%**
ระบบได้ย้ายเอกสารต้นฉบับจากโฟลเดอร์ `doc/`, `design/`, และ `database/` เข้าสู่สารบบ Wiki ครบทุกหน้าแล้ว สามารถค้นหาและอ้างอิงผ่าน `index.md` ได้ทันที

---

### 2. Query — ถามคำถามเกี่ยวกับโปรเจค

ถามคำถามกับ LLM ได้เลย เช่น:

```
"ระบบคำนวณ Risk Score อย่างไร?"
"เพราะอะไรถึงเลือก SegFormer แทน CNN?"
"เปรียบเทียบข้อดีข้อเสียของ 3 analysis layer"
"PDPA compliance ทำอะไรบ้างในระบบนี้?"
"อธิบาย Heatmap ให้คนไม่มีพื้น AI เข้าใจ"
```

LLM จะ:

- อ่าน `index.md` เพื่อหาหน้าที่เกี่ยวข้อง
- อ่านหน้าเหล่านั้น
- ตอบพร้อม cite ชื่อหน้า wiki

**Tip:** ถ้าคำตอบที่ได้มีประโยชน์และใช้ซ้ำได้ บอก LLM ให้บันทึกเป็นหน้า wiki ใหม่:

```
"บันทึกคำตอบนี้เป็นหน้า wiki ใหม่ชื่อ decisions/risk-score-design-rationale.md"
```

คำตอบและการวิเคราะห์ที่ดีจะสะสมใน wiki และไม่หายไปกับ chat history

---

### 3. Lint — ตรวจสุขภาพ Wiki

บอก LLM เป็นระยะๆ ว่า:

```
"lint wiki"
```

LLM จะตรวจหา:

- หน้าที่ไม่มีหน้าอื่น link มาถึง (orphan pages)
- ข้อมูลขัดแย้งระหว่างหน้า
- แนวคิดสำคัญที่ถูกพูดถึงแต่ยังไม่มีหน้าของตัวเอง
- cross-reference ที่ขาดหายไป
- frontmatter ที่ไม่ครบ
- เอกสารที่มี update ใหม่แต่หน้า wiki ยังไม่ได้รับการอัปเดต

---

## Convention ของแต่ละหน้า

ทุกหน้าใน wiki เริ่มด้วย YAML frontmatter:

```markdown
---
title: "ชื่อหน้า"
category: concepts | architecture | entities | decisions | requirements | planning
tags: [tag1, tag2]
sources: [path/to/source.md]
updated: YYYY-MM-DD
---
```

ตามด้วยโครงสร้างเนื้อหา:

1. ประโยคสรุปสั้นๆ (1 บรรทัด)
2. เนื้อหาหลักแบ่งเป็น H2/H3 sections
3. ส่วน "Key Points" หรือ "Summary"
4. ส่วน "Related Pages" ที่ด้านล่างสุด

---

## Wikilinks (Obsidian-style)

Wiki ใช้ syntax ของ Obsidian ในการ link ระหว่างหน้า:

| Syntax | ผลลัพธ์ |
| :--- | :--- |
| `[[overview]]` | link ไปหน้า `overview.md` |
| `[[concepts/semantic-segmentation]]` | link ไปหน้าใน subfolder |
| `[[concepts/semantic-segmentation\|Semantic Segmentation]]` | link แต่แสดงข้อความว่า "Semantic Segmentation" |

---

## ไฟล์สำคัญ

| ไฟล์ | หน้าที่ |
| :--- | :--- |
| [`AGENTS.md`](AGENTS.md) | คู่มือ LLM — schema และ workflow สำหรับ agent |
| [`index.md`](index.md) | สารบัญ — อัปเดตทุกครั้งที่มีหน้าใหม่ |
| [`log.md`](log.md) | บันทึก — append-only, ห้ามลบ entry เก่า |
| [`overview.md`](overview.md) | ภาพรวมโปรเจค — จุดเริ่มต้นสำหรับคนใหม่ |

---

## ตัวอย่าง Session การทำงาน

```
คุณ:   "ingest design/training.md เข้า wiki"
LLM:   อ่านไฟล์ → อัปเดต concepts/ai-model-segformer.md
       → สร้าง concepts/model-training.md ใหม่
       → อัปเดต index.md → บันทึก log.md

คุณ:   "ทำไม SegFormer ถึงดีกว่า CNN สำหรับโปรเจคนี้?"
LLM:   อ่าน index.md → อ่าน concepts/ai-model-segformer.md
       + decisions/technology-choices.md → ตอบพร้อม cite

คุณ:   "บันทึกคำตอบนี้เป็นหน้า wiki"
LLM:   สร้าง decisions/segformer-vs-cnn-rationale.md
       → อัปเดต index.md + log.md
```

---

## สิ่งที่คุณทำ vs สิ่งที่ LLM ทำ

| คุณ (Human) | LLM |
| :--- | :--- |
| หาเอกสารและแหล่งข้อมูลใหม่ | อ่าน สรุป และเขียนหน้า wiki |
| ตั้งคำถามและสำรวจความรู้ | ค้นหาและ synthesize คำตอบจาก wiki |
| บอกว่าอะไรสำคัญหรือควรเน้น | ทำ cross-reference และ maintenance |
| Browse ผลลัพธ์ใน Obsidian | อัปเดต index และ log ทุกครั้ง |

---

## หมายเหตุสำคัญ

- เอกสารต้นฉบับใน `doc/` และ `design/` คือ **raw sources** — LLM อ่านได้แต่ไม่แก้ไขเด็ดขาด
- Wiki ใน `wiki/` คือ **living document** — LLM เป็นเจ้าของและดูแลทั้งหมด
- `log.md` เป็น append-only — ห้ามลบ entry เก่า เพื่อให้ trace timeline ของ wiki ได้
- ถ้า wiki โตขึ้นมากจนค้นหาลำบาก ให้พิจารณาติดตั้ง [qmd](https://github.com/taylorai/qmd) สำหรับ hybrid search (BM25 + vector) บน local machine
