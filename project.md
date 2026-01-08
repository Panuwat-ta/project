# Mobile App: Scam Image Detection

## 1. ภาพรวมโปรเจค

สร้าง **Mobile App** ที่มีฟีเจอร์ช่วยตรวจจับรูปภาพที่ใช้ในการหลอกลวง (Scam / Fraud Image Detection) โดยใช้เทคโนโลยี **AI** วิเคราะห์ลักษณะของรูป ทั้งจากเนื้อหา (visual features), metadata (EXIF), และการค้นหารูปซ้ำในอินเทอร์เน็ต (reverse image search) เพื่อให้ผู้ใช้สามารถตรวจสอบได้ทันทีว่ารูปมีความเสี่ยงถูกนำมาใช้หลอกหรือไม่

**เป้าหมายหลัก:** ลดความเสี่ยงจากการถูกหลอกลวงด้วยรูปภาพ (เช่น ประกาศขายปลอม, โปรไฟล์ปลอม, รูปโฆษณาเท็จ)

---

## 2. ผู้ใช้งานเป้าหมาย

* ผู้ใช้งานทั่วไปที่ต้องการตรวจสอบรูปก่อนแชร์/ซื้อ/เชื่อถือ
* แอดมินของ marketplace หรือแพลตฟอร์มโซเชียล (เป็นเวอร์ชันสำหรับองค์กร)
* นักวิจัย/นักพัฒนาอยากทดสอบโมเดลตรวจจับภาพหลอก

---

## 3. ฟีเจอร์หลัก (MVP)

1. **อัปโหลดรูป / ถ่ายรูปด้วยกล้อง** เพื่อสแกนตรวจสอบ
2. **ผลการประเมินความเสี่ยง** (เปอร์เซนต์ + คำอธิบายสั้น) เช่น: "น่าจะเป็นภาพที่ถูกตัดต่อ / สร้างด้วย AI / พบการใช้งานซ้ำบนเว็บ"
3. **แสดงเหตุผล (explainability)** เช่น จุดที่น่าสงสัย, ลักษณะที่โมเดลตรวจจับได้ (face anomaly, inconsistent shadows)
4. **ค้นหารูปภาพซ้ำ (reverse image search)** — หาแหล่งที่รูปนั้นปรากฏบนเว็บ (URL ตัวอย่าง)
5. **ประวัติการสแกน** และการบันทึกผลเพื่อกลับมาดู
6. **ปุ่มรายงาน** หากผู้ใช้ยืนยันว่าเป็นการหลอกลวงจริง (ช่วยเก็บข้อมูลสำหรับปรับปรุงโมเดล)

---

## 4. ฟีเจอร์เพิ่มเติม (Stretch)

* ตรวจสอบว่าเป็นรูปที่สร้างด้วยโมเดลภาพ (AI-generated) หรือไม่ (GAN/Stable Diffusion indicator)
* วิเคราะห์ข้อความบนภาพ (OCR) เพื่อตรวจคำหลอกลวง เช่น เบอร์บัญชี/ราคาแปลกๆ
* ระบบคะแนนความเชื่อถือของผู้ใช้ (trust score)
* API สำหรับองค์กร (ตรวจรูปจำนวนมากแบบ batch)
* Integration กับแพลตฟอร์มโซเชียล/marketplace ผ่าน plugin

---

## 5. สถาปัตยกรรมระบบ (เสนอ)

**Client (Mobile App)**

* Flutter (iOS + Android) หรือ React Native
* UI: หน้าอัปโหลด, หน้าแสดงผล, ประวัติ, การตั้งค่า

**Backend / AI Service**

* FastAPI (Python) หรือ Node.js Express (แต่โมเดลเป็น Python สะดวกกว่า)
* Model serving: ONNX Runtime / TorchServe / TensorFlow Serving
* Reverse image search: ผสานกับบริการภายนอก (Google Vision API / Bing Visual Search / TinEye) หรือทำระบบ index ด้วย embeddings (FAISS)
* Database: PostgreSQL (user, history), Redis (cache)
* Storage: S3-compatible (รูปอัปโหลดชั่วคราว)

**AI Components**

* Image forgery detection model (binary classifier) — ตรวจจับการตัดต่อ
* AI-generated image detector (separate model)
* Embedding model (CLIP/Vision Transformer) สำหรับค้นหารูปซ้ำ/nearest neighbor
* Heuristics: EXIF inconsistency, compression artifacts, error level analysis

---

## 6. ข้อมูลและแหล่งข้อมูลฝึก (Dataset suggestions)

* Datasets สำหรับการตรวจจับการปลอมแปลง/ตัดต่อ: CASIA, COVERAGE, Columbia Image Splicing
* AI-generated datasets: GAN, ProGAN, StyleGAN, Stable Diffusion samples (สร้างตัวอย่างเองหรือใช้ dataset ที่เผยแพร่)
* Reverse-image index: เก็บเว็บตัวอย่างจาก Common Crawl (ต้องระวังเรื่องสิทธิ์)
* เพิ่มข้อมูลจากการรายงานของผู้ใช้ (privacy-safe)

---

## 7. วิธีการออกแบบโมเดล (high-level)

1. **Preprocessing:** ปรับขนาด, normalize, ดึง metadata, ทำ Error Level Analysis (ELA)
2. **Feature extraction:** ใช้ backbone เช่น ResNet / ViT / EfficientNet เพื่อดึง embedding
3. **Classifier heads:**

   * Head A: binary classifier for forged vs real
   * Head B: classifier for AI-generated vs camera photo
   * Head C: OCR text detector (Tesseract / easyOCR) + NLP classifier for scam phrases
4. **Explainability:** Grad-CAM หรือ attention map เพื่อโชว์ตำแหน่งความผิดปกติ

---

## 8. เกณฑ์ประเมินความสำเร็จ (Metrics)

* **Precision / Recall** ของการตรวจจับภาพหลอก
* **AUC-ROC** สำหรับ classifier
* **False Positive Rate** (ต้องต่ำพอ ไม่ให้ผู้ใช้หงุดหงิด)
* **Latency:** เวลาตอบกลับไม่เกินเป้าหมาย (ตัวอย่าง: < 3s สำหรับภาพขนาดมาตรฐาน)

---

## 9. ความเป็นส่วนตัวและจริยธรรม

* รูปภาพของผู้ใช้ต้องถูกลบหรือเข้ารหัสเมื่อสิ้นสุดการสแกน (กำหนดเวลา auto-delete)
* แจ้งผู้ใช้ว่าอัลกอริธึมเป็นการประมาณค่า ไม่ใช่คำตัดสินแน่นอน
* ให้ทางเลือกไม่เก็บรูป/ไม่ส่งไปยังเซิร์ฟเวอร์ (on-device inference) หากเป็นไปได้
* ระวัง bias ใน dataset (เช่น การตัดสินรูปคนจากชาติ/สีผิว)

---

## 10. UI / UX (สเก็ตช์เป็นข้อความ)

1. **หน้าแรก:** ปุ่ม "ถ่ายรูป" / "อัปโหลดรูป" + ตัวอย่างวิธีใช้งานสั้นๆ
2. **หน้าสแกน:** แถบสถานะ (กำลังวิเคราะห์) + loader
3. **หน้าผลลัพธ์:** คะแนนความเสี่ยง (เช่น 78%) + เหตุผลสั้นๆ + ปุ่มดูรายละเอียด (ตำแหน่งที่น่าสงสัย) + ปุ่มแชร์/รายงาน
4. **หน้าประวัติ:** ลิสต์รูปที่สแกนพร้อมคะแนนและวันที่
5. **หน้าการตั้งค่า:** นโยบายความเป็นส่วนตัว, ตั้งเวลา auto-delete

---

## 11. User Stories & Acceptance Criteria (ตัวอย่าง)

**User Story 1 (MVP)**

* *ในฐานะผู้ใช้* ฉันอยากอัปโหลดรูปเพื่อให้แอปวิเคราะห์ว่าเป็นรูปหลอกหรือไม่ เพื่อที่ฉันจะได้ไม่ถูกหลอกบนโซเชียล
* *Acceptance Criteria:* เมื่ออัปโหลดรูป ระบบต้องแสดงผลการวิเคราะห์ (risk score) ภายใน 10 วินาที และแสดงเหตุผลอย่างน้อย 1 ข้อ

**User Story 2**

* *ในฐานะผู้ใช้* ฉันอยากเห็นจุดที่ภาพมีความผิดปกติ
* *Acceptance Criteria:* ระบบต้องแสดง heatmap หรือ bounding box ครั้งละหนึ่งตำแหน่งที่โมเดลตรวจพบ

**User Story 3**

* *ในฐานะแอดมินของ marketplace* ฉันอยากตรวจรูปแบบ batch เพื่อแบนใบประกาศที่มีความเสี่ยงสูง
* *Acceptance Criteria:* ระบบต้องรองรับการอัปโหลด CSV ลิงก์รูป และคืนผลแบบ batch พร้อมสถานะ

---

## 12. Roadmap / แผนพัฒนา (ตัวอย่าง 8 สัปดาห์)

* **สัปดาห์ 1-2:** เก็บ requirement, ออกแบบ UI/UX, เตรียม dataset
* **สัปดาห์ 3-4:** พัฒนา backend + model prototype (training baseline)
* **สัปดาห์ 5:** พัฒนา mobile UI (upload + result flow) และเชื่อม API
* **สัปดาห์ 6:** ปรับปรุงโมเดล, เพิ่ม explainability
* **สัปดาห์ 7:** ทดสอบ end-to-end, UX testing, security review
* **สัปดาห์ 8:** ปรับแก้ตาม feedback, deploy (staging) และเตรียม demo

---

## 13. เครื่องมือ & ไลบรารีที่แนะนำ

* Mobile: Flutter หรือ React Native
* Backend: FastAPI, Gunicorn / Uvicorn
* ML: PyTorch / TensorFlow, ONNX Runtime
* Embeddings & Index: CLIP, FAISS
* OCR: Tesseract, easyOCR
* DevOps: Docker, GitHub Actions, AWS/GCP/Azure (S3, RDS)

---

## 14. Testing & Validation

* สร้างชุดทดสอบแยก (hold-out) ที่มีภาพจริง/ภาพปลอม/AI-generated
* Unit tests สำหรับ API
* Integration tests สำหรับ flow อัปโหลด→ผลลัพธ์
* UX testing กับกลุ่มผู้ใช้จริง (collect qualitative feedback)

---


