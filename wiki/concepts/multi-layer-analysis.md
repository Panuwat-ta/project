---
title: "การวิเคราะห์หลายชั้น (Multi-layer Analysis)"
category: concepts
tags: [การวิเคราะห์, OCR, NLP, reverse-image-search, visual-anomaly, pipeline]
sources: [Document/srs.md, design/architecture.md, README.md]
updated: 2026-08-02
---

# การวิเคราะห์หลายชั้น (Multi-layer Analysis)

กลยุทธ์การตรวจจับหลักของระบบ แทนที่จะพึ่งพาสัญญาณเดียว ระบบรัน 3 ชั้นการวิเคราะห์โดยอิสระและรวมผลออกมาเป็นคะแนนความเสี่ยงเดียว

---

## ชั้นที่ 1: วิเคราะห์ข้อความ (Textual Analysis) — สเกลคะแนนอิสระ 0–100%

ดึงข้อมูลและวิเคราะห์ข้อความที่ฝังอยู่ในรูปภาพ

**ขั้นตอน:**

1. **OCR** — ส่งภาพเข้า Surya-OCR (รองรับภาษาไทยและอังกฤษ) เพื่อดึงข้อความทั้งหมด
2. **NLP keyword matching** — นำข้อความที่ได้มาวิเคราะห์ด้วย Regular Expression และ/หรือโมเดล NLP ขนาดเล็ก เพื่อหารูปแบบที่บ่งชี้การหลอกลวง

**สัญญาณที่ตรวจจับ:**

- ภาษาแสดงความเร่งด่วน ("ด่วน", "urgent", "โอนด่วน")
- คำสัญญาผลตอบแทนสูง ("รับปันผลสูง", "กำไรรับประกัน")
- ชื่อบัญชีหรือเบอร์โทรที่อยู่ใน Blacklist
- คำสั่งทางการเงินที่น่าสงสัย

**ผลลัพธ์:** คะแนนความเสี่ยงจากข้อความ (S_text) 0–100%

---

## ชั้นที่ 2: ตรวจสอบแหล่งที่มา (Source Verification) — สเกลคะแนนอิสระ 0–100%

ตรวจสอบว่ารูปภาพเคยถูกเผยแพร่บนอินเทอร์เน็ตหรือไม่ — เป็นตัวบ่งชี้สำคัญของการนำภาพไปใช้ซ้ำในเชิงหลอกลวง

**ขั้นตอน:**

1. ส่งรูปภาพ (หรือ URL) ไปยัง **Google Vision API** เพื่อค้นหาภาพย้อนกลับ (Reverse Image Search)
2. ระบบนับจำนวนแหล่งที่มาที่แตกต่างกันที่พบภาพคล้ายกัน

**เกณฑ์การให้คะแนน:**

- พบ >= 3 แหล่งที่แตกต่างกัน → ความเสี่ยงจากแหล่งที่มาสูง (ภาพถูกเผยแพร่กว้าง อาจเป็นภาพแอบอ้าง)
- พบ <= 1 แหล่ง → ความเสี่ยงต่ำ (ดำเนินการตรวจสอบภาพ AI-Generated ต่อ)

**ผลลัพธ์:** คะแนนความเสี่ยงจากแหล่งที่มา (S_source) 0–100%

---

## ชั้นที่ 3: ตรวจจับความผิดปกติทางภาพ (Visual Anomaly Detection) — สเกลคะแนนอิสระ 0–100%

ชั้นที่วัดระดับการตัดต่อ/สังเคราะห์ภาพโดยตรง ใช้ Deep Learning ตรวจจับการดัดแปลงระดับพิกเซล

การตรวจสอบย่อย 2 อย่าง:

- **ตรวจจับการตัดต่อภาพ (Semantic Segmentation-based)** — ตรวจจับ splicing, copy-move และการแก้ไขพิกเซล ดูที่ [[concepts/semantic-segmentation]] และ [[concepts/ai-model-segformer]]
- **ตรวจจับภาพสังเคราะห์จาก AI** — จำแนกว่าภาพถูกสร้างโดยโมเดล Generative AI (เช่น GAN, Diffusion model) หรือไม่

**ผลลัพธ์:** คะแนนความเสี่ยงทางภาพ (S_visual) 0–100% พร้อม **Heatmap** สำหรับ XAI ดูที่ [[concepts/explainable-ai]]

---

## การไหลของ Pipeline

```
ผู้ใช้อัปโหลดภาพ
        |
  ตรวจสอบและ Preprocess
        |
  ตรวจสอบ Redis Cache
  ├── Cache Hit → ดึงผลลัพธ์เก่ากลับมาทันที
  └── Cache Miss → รัน Pipeline:
          Task 1: ดึง Metadata/EXIF
          Task 2: OCR & Textual Analysis  → S_text (0-100%)
          Task 3: Visual Forgery Detection → S_visual (บางส่วน)
               |
          พบคำหลอกลวง? → ส่งไป Aggregator ทันที
               |
          Task 4: Reverse Image Search → S_source (0-100%)
               |
          >= 3 แหล่ง? → ความเสี่ยงแหล่งที่มาสูง
          < 2 แหล่ง? → Task 5: AI-Gen Detection → S_visual (ครบ 0-100%)
               |
          Aggregator: คำนวณ Overall Risk Score (Hybrid Worst-Case Trigger + Multi-factor Compounding)
               |
          สร้างคำอธิบาย XAI พร้อม Breakdown 3 มิติ
               |
          เก็บข้อมูลใน PostgreSQL, cache hash ใน Redis
               |
          ส่ง JSON ผลลัพธ์กลับ Client
```

---

## EXIF Metadata กับ Pipeline

ก่อนรัน 3 ชั้นหลัก API Gateway จะดึง **EXIF Metadata** (พิกัด GPS, รุ่นกล้อง, Software ที่ใช้, วันเวลา) เพื่อตรวจหาความไม่สอดคล้องเบื้องต้น เช่น ไม่มีข้อมูล GPS ทั้งที่อ้างว่าถ่ายที่ใดที่หนึ่ง หรือ metadata แสดงว่าใช้โปรแกรมแต่งภาพ

---

## ประเด็นสำคัญ

- ทั้ง 3 มิติประเมินคะแนนแยกกันเป็นอิสระ (0–100%) ตามหลัก Fraud Detection & Forensics
- สรุปคะแนนรวมด้วยหลัก **Worst-Case Trigger**: $S_{base} = \max(S_{visual}, S_{text}, S_{source})$ เพื่อป้องกันปัญหา Dilution ไม่ให้ด้านที่ปลอดภัยมาฉุดคะแนนด้านที่อันตรายลง
- เสริมคะแนนด้วย **Multi-Factor Compounding**: หากพบความเสี่ยงปานกลางขึ้นไปในมิติอื่น ($\ge 40$) จะเพิ่มคะแนนความเสี่ยง +5 ต่อมิติ
- การ Cache ด้วย Redis image hash ทำให้การส่งรูปซ้ำได้รับคำตอบทันทีโดยไม่ต้องรัน AI ซ้ำ

---

## หน้าที่เกี่ยวข้อง

- [[concepts/risk-scoring]]
- [[concepts/semantic-segmentation]]
- [[concepts/ai-model-segformer]]
- [[concepts/explainable-ai]]
- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
- [[architecture/external-integrations]]
