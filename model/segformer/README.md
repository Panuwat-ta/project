# คู่มือฉบับละเอียด: การสร้างและใช้งานโมเดล SegFormer ตรวจจับสลิปปลอม

พื้นที่นี้ (`model/segformer/`) คือหัวใจหลักของ **AI Inference Service** ในระบบหลังบ้าน (Backend) ของคุณ โดยทำหน้าที่รับรูปภาพสลิปมาวิเคราะห์และส่งแผนที่ความร้อน (Heatmap) ที่ระบุจุดตัดต่อกลับไปยัง Mobile App

การทำงานจะแบ่งเป็น 4 ระยะ (Phases) ดังนี้:

---

## 0: การติดตั้งสภาพแวดล้อม (Environment Setup)
เพื่อให้แน่ใจว่าเวอร์ชันของไลบรารีต่างๆ ทำงานร่วมกันได้อย่างสมบูรณ์แบบ ให้ทำการติดตั้งสภาพแวดล้อมจำลอง (Virtual Environment) ดังนี้:

1. สร้างและเปิดใช้งาน Virtual Environment:
```bash
python -m venv env
source env/bin/activate
```

2. ติดตั้งแพ็กเกจพื้นฐานตามที่ล็อกสเปคไว้ (PyTorch, Numpy, OpenCV ฯลฯ):
```bash
pip install -r requirements.txt
```

3. ติดตั้ง MMCV ผ่าน `mim` เพื่อดึงไฟล์สำเร็จรูปมาใช้โดยไม่ต้องคอมไพล์เอง:
```bash
mim install "mmcv==2.1.0"
```

---

## 1: การเตรียมข้อมูลสอน AI (Dataset Preparation)
AI จะไม่รู้ว่า "รอยตัดต่อ" คืออะไรจนกว่าเราจะสอนมัน คุณต้องสร้างชุดข้อมูล (Dataset) เลียนแบบของจริง โดยต้องมีภาพ 2 ประเภทคู่กันเสมอ:
1. **ภาพสลิป (Images):** ภาพสลิปโอนเงินทั้งของจริงและของปลอม
2. **ภาพหน้ากาก (Masks/Annotations):** ภาพขาวดำล้วนๆ ที่มีขนาดเท่ากับภาพสลิปเป๊ะๆ 
   - **พิกเซลสีดำ (ค่า 0):** คือบริเวณที่ปกติ
   - **พิกเซลสีขาว (ค่า 1):** คือบริเวณที่ถูกแก้ตัวเลข หรือตัดต่อ

Google Drive: [dataset](https://drive.google.com/file/d/1jxQS3HwH0DHHHaCtf_prKPj6fMUpZ5jp/view?usp=sharing)

---

## 2: การตั้งค่าคอนฟิก (Configuration)
เราจะใช้ไฟล์ `configs/segformer_mit-b2.py` เป็นตัวคุมพฤติกรรมของ AI 
มันถูกเขียนทับ (Override) ค่าพื้นฐานเพื่อ:
1. เปลี่ยนคลาสให้รู้จักแค่ 2 ชนิด (ปกติ กับ ตัดต่อ) 
2. ชี้ Path ของ Dataloader ไปที่โฟลเดอร์ `data/scam_dataset/` ที่เราเก็บรูปไว้

---

## 3: การเทรนโมเดล (Transfer Learning)
เราจะเอา "สมองเดิม" ของ AI มาสอน "ความรู้ใหม่"
เปิด Terminal ตรวจสอบว่าอยู่ในโฟลเดอร์ `model/segformer/` แล้วรันคำสั่ง:

```bash
python library/mmsegmentation/tools/train.py configs/segformer_mit-b2.py

# การหยุดและกลับมาทำต่อ
python library/mmsegmentation/tools/train.py configs/segformer_mit-b2.py --resume
```
**ผลลัพธ์ที่ได้:** เมื่อรอจนกระบวนการเทรนเสร็จสิ้น ระบบจะสร้างไฟล์ `.pth ตัวใหม่` ของคุณเอง (ชื่อ `latest.pth`) ไว้ในโฟลเดอร์ `work_dirs/` 

---

## 4: การนำไปใช้จริงบน Backend API (Inference)
ตอนนี้คุณได้ AI ที่ฉลาดและพร้อมทำงานแล้ว ให้นำไฟล์ `.pth` ตัวใหม่ มาใช้งานในเซิร์ฟเวอร์

สามารถดูตัวอย่างการเรียกใช้งานได้ในไฟล์ `predict.py` 
คำสั่งรันทดสอบ:
```bash
python predict.py
```
เมื่อรันสำเร็จ สคริปต์จะสร้างภาพ `result_heatmap.jpg` ส่งกลับมาให้ดูว่า AI จับผิดจุดไหนได้บ้าง
