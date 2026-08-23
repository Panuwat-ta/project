---
title: "การตัดสินใจเลือกเทคโนโลยี (Technology Choices)"
category: decisions
tags: [decisions, tradeoffs, Flutter, SegFormer, FastAPI, ONNX, PostgreSQL]
sources: [design/architecture.md, design/model.md]
updated: 2026-08-02
---

# การตัดสินใจเลือกเทคโนโลยี

การตัดสินใจเลือกเทคโนโลยีหลัก ทางเลือกที่พิจารณา และเหตุผลทางวิศวกรรม

---

## การตัดสินใจ 1: ใช้ Flutter สำหรับ Mobile

**สิ่งที่เลือก:** Flutter (Dart)
**ทางเลือก:** React Native (JavaScript)

**เหตุผล:**

- Flutter ให้ Codebase เดียว (Dart) สำหรับ Android (และ iOS ในอนาคต)
- ประสิทธิภาพการ Render ดีกว่า — Flutter วาด Widget ของตัวเองโดยไม่ต้องพึ่ง Native UI Component Bridge
- รองรับ Dark Mode ทันที
- BLoC State Management มี Document ครบถ้วนและเขียน Test ง่าย

**สรุป:** โครงการนี้ใช้ **Flutter** เป็นเทคโนโลยีหลักสำหรับการพัฒนาแอปพลิเคชันมือถือ ดูข้อมูลเพิ่มเติมที่ [[entities/tech-stack]]

---

## การตัดสินใจ 2: ใช้ SegFormer แทน CNN สำหรับตรวจภาพตัดต่อ

**สิ่งที่เลือก:** SegFormer (Transformer-based semantic segmentation)
**ทางเลือก:** CNN-based Classifiers (ResNet, EfficientNet), Traditional Semantic Segmentation Standalone

**เหตุผล:**

- งานนี้ต้องระบุการดัดแปลงใน **ระดับพิกเซล** ซึ่งเป็นปัญหา Segmentation ไม่ใช่ Classification แบบ CNN ที่บอกแค่ Label รวมๆ
- SegFormer จัดการเรื่อง Multi-scale Features (ทั้ง Global Context และ Local Pixel Detail) ได้ดีกว่า Transformer รุ่นแรกๆ
- ไม่มี Fixed Positional Encoding → Generalize กับรูปหลายขนาดได้ดีกว่า
- เร็วกว่า ViT-based Model ตัวเต็ม
- นำไปใช้ร่วมกับ Semantic Segmentation Preprocessing ได้ดี

**ข้อแลกเปลี่ยน (Trade-off):** กิน RAM/VRAM มากกว่า CNN Classifier แต่ยอมรับได้เมื่อรันบน Cloud

---

## การตัดสินใจ 3: ใช้ FastAPI แทน Django/Flask/Node.js สำหรับ Backend

**สิ่งที่เลือก:** Python FastAPI
**ทางเลือก:** Django REST Framework, Flask, Node.js Express

**เหตุผล:**

- **Async I/O** — FastAPI จัดการ Concurrent Request ได้อย่างมีประสิทธิภาพโดยไม่ติดเรื่อง Threading Overhead
- **Performance** — Throughput สำหรับงาน I/O-bound เทียบชั้นได้กับ Go และ Node.js
- **Pydantic Validation** — ตรวจสอบ Schema เข้า-ออกแบบอัตโนมัติ
- **OpenAPI Docs** — สร้าง API Document ให้โดยอัตโนมัติที่ `/docs`
- ใช้ภาษา Python เช่นเดียวกับฝั่ง AI/ML ทำให้ทีมดูแลรักษาง่ายกว่าต้องสลับภาษา

---

## การตัดสินใจ 4: ใช้ ONNX Runtime แทน Native PyTorch เพื่อ Serving

**สิ่งที่เลือก:** ONNX Runtime (เฉพาะตอน Serving)
**การเทรน (Training):** ยังใช้ PyTorch เหมือนเดิม

**เหตุผล:**

- Inference เร็วกว่า Native PyTorch 2–5 เท่า
- ONNX ทำงานแยกจาก Framework — สามารถรัน Model ได้โดยไม่ต้องลง PyTorch ในฝั่ง Inference
- ลด Dependency และขนาด Container ของฝั่ง Serving
- Flow มาตรฐาน: Train ใน PyTorch → Export เป็น ONNX → Serve ด้วย ONNX Runtime

---

## การตัดสินใจ 5: ใช้ PostgreSQL เป็นฐานข้อมูลหลัก

**สิ่งที่เลือก:** PostgreSQL
**ทางเลือก:** MongoDB, Firestore (NoSQL)

**เหตุผล:**

- ระบบต้องการ **ACID Transactions** เพื่อรักษาความถูกต้องของข้อมูลสแกนและการเก็บ Consent PDPA
- ข้อมูลมีโครงสร้างแบบ Relational ชัดเจน (Users → Scans → Results, Reports)
- มี Extension PostGIS เผื่ออนาคตหากต้องการฟีเจอร์แผนที่จาก EXIF GPS
- เป็นฐานข้อมูลที่มีเสถียรภาพและได้รับความนิยมสูง

---

## การตัดสินใจ 6: ใช้ Google Vision API สำหรับ Reverse Image Search

**สิ่งที่เลือก:** Google Vision API
**ทางเลือก:** Bing Visual Search

**เหตุผล:**

- ฐานข้อมูลภาพบนเว็บใหญ่และครอบคลุมที่สุด
- เรียก API ครั้งเดียวสามารถค้นหาครอบคลุมอินเทอร์เน็ตส่วนใหญ่
- เสถียรและมี Document อธิบาย API ดีเยี่ยม

**ความเสี่ยง:** ยึดติดกับบริการภายนอก — หาก Google Vision ล่ม ระบบตรวจสอบความเสี่ยงจะคืนค่าคะแนนกลางสำหรับส่วนนี้ (Source Verification) โดยมี Bing เป็นแผนสำรอง

## การตัดสินใจ 7: ใช้ Surya OCR 2 (GGUF/Qwen2.5-VL) แทน Tesseract สำหรับอ่านตัวอักษร

**สิ่งที่เลือก:** Surya OCR 2 (รันผ่าน llama-cpp-python รูปแบบ GGUF)
**ทางเลือก:** Tesseract OCR (ดั้งเดิม), Google Cloud Vision API (Text Detection)

**เหตุผล:**

- Tesseract OCR ขาดความแม่นยำในการอ่านภาษาไทย โดยเฉพาะรูปที่มีพื้นหลังลวดลายเยอะหรือมีสัญญาณรบกวน (Noise)
- Surya OCR 2 อาศัยสถาปัตยกรรม Vision-Language Model (Qwen2.5-VL) ทำให้มีความเข้าใจบริบท โครงสร้างภาพ (Layout) และภาษาไทยได้แม่นยำกว่ามาก
- การใช้ GGUF + `llama-cpp-python` ช่วยให้สามารถรันโมเดลบน GPU VRAM 4GB (เช่น RTX 3050) ได้อย่างมีประสิทธิภาพ และยัง Fallback ไปรันบน CPU ได้ถ้าไม่มี GPU
- ช่วยคัดกรอง "Scam Keywords" หลอกลวง (เช่น ด่วน, โบนัส, กู้เงิน) ได้แม่นยำ ลด False Negative

---

## ประเด็นสำคัญ

- การตัดสินใจเลือกเทคโนโลยีเกือบทั้งหมดอิงจาก Requirement: เช่น ต้องการผลระดับพิกเซล, PDPA Compliance, ประสิทธิภาพ, และทีมถนัด Python
- Trade-off ที่ยอมรับคือ SegFormer กิน Memory เยอะกว่า แต่นำมาซึ่งความแม่นยำของ Segmentation
- ONNX Runtime คือการ Optimization เพื่อความเร็วล้วนๆ ไม่ต้องแลกเปลี่ยนกับประสิทธิภาพของอัลกอริทึม

---

## หน้าที่เกี่ยวข้อง

- [[entities/tech-stack]]
- [[concepts/ai-model-segformer]]
- [[architecture/system-architecture]]
- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
