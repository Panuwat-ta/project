# โครงสร้างโฟลเดอร์สำหรับงานพัฒนาโมเดล AI (AI Model Development Structure)

โฟลเดอร์ `model/` ถูกจัดโครงสร้างโดยรวมศูนย์การทำงานไว้ที่ `segformer/` ซึ่งแยก "ไลบรารีภายนอก" ออกจาก "โค้ดแอปพลิเคชัน" อย่างชัดเจน เพื่อความสะดวกในการดูแลรักษา การเทรน และนำไปเชื่อมต่อกับ FastAPI

## โครงสร้างโฟลเดอร์แบบละเอียด (Detailed Directory Tree)

```text
/home/panuwat/project/model/
│
├── segformer/                # [แอปพลิเคชันหลัก] โค้ดและข้อมูลเฉพาะสำหรับโปรเจคสแกนสลิป
│   │
│   ├── env/                  # สภาพแวดล้อมจำลอง (Virtual Environment) สำหรับติดตั้ง Dependency
│   │
│   ├── library/
│   │   └── mmsegmentation/   # โค้ดต้นฉบับจาก OpenMMLab
│   │       ├── configs/      # ไฟล์คอนฟิกพื้นฐานทั้งหมด (เช่น โครงสร้าง SegFormer)
│   │       ├── mmseg/        # โค้ดกลไกภายใน (Model, Loss, Datasets)
│   │       ├── tools/        # สคริปต์สำเร็จรูป เช่น train.py, test.py, pytorch2onnx.py
│   │       └── ...           # (ห้ามแก้ไขโค้ดใดๆ ในโฟลเดอร์นี้)
│   │
│   ├── data/                 # แหล่งจัดเก็บข้อมูลสำหรับสอน AI
│   │   └── slip_dataset/
│   │       ├── images/       # รูปภาพสลิปต้นฉบับ (คำถาม)
│   │       │   ├── train/    # - รูปสลิปสำหรับสอน
│   │       │   └── val/      # - รูปสลิปสำหรับสอบวัดผล
│   │       └── annotations/  # รูปภาพหน้ากากขาว-ดำ (เฉลยรอยตัดต่อ)
│   │           ├── train/    # - เฉลยของรูปภาพใน images/train
│   │           └── val/      # - เฉลยของรูปภาพใน images/val
│   │
│   ├── configs/              # โฟลเดอร์เก็บไฟล์ตั้งค่าเฉพาะ (Custom Configs)
│   │   └── segformer_mit-b2.py
│   │                         # ไฟล์คอนฟิกของเราเอง ที่ทำการเขียนทับ (Override):
│   │                         # 1. เปลี่ยน num_classes = 2
│   │                         # 2. ชี้ Path ของ Dataloader ไปที่ data/slip_dataset/
│   │                         # 3. อ้างอิง _base_ กลับไปยัง library/mmsegmentation/...
│   │
│   ├── work_dirs/            # (สร้างอัตโนมัติเมื่อสั่งเทรน) แหล่งเก็บผลลัพธ์การเรียนรู้
│   │   └── segformer_mit-b2.../
│   │       ├── epoch_*.pth   # ไฟล์น้ำหนักที่ถูกบันทึกระหว่างการเทรน
│   │       ├── latest.pth    # ไฟล์น้ำหนักตัวล่าสุดที่เทรนสำเร็จ
│   │       └── training.log  # ล็อกบันทึกความแม่นยำ (Loss/mIoU)
│   │
│   ├── prepare_dataset.py    # สคริปต์จัดการ Dataset (เช่น แปลงค่าสี, สุ่มแบ่ง Train/Val)
│   ├── requirements.txt      # ไฟล์รวมรายการ Dependency ที่ต้องใช้ (เช่น PyTorch, mmcv)
│   ├── predict.py            # สคริปต์ Python สำหรับรันทดสอบ (Inference) โหลด .pth มาพ่น Heatmap
│   └── README.md             # คู่มืออธิบายวิธีเตรียมข้อมูลและการสั่งรันเทรนโมเดล
│
└── doc.md                    # เอกสารอธิบายโครงสร้างและการออกแบบ (ไฟล์นี้)
```

## กระบวนการทำงาน (Workflow)

หากคุณอยู่ที่พาธ `project/model/segformer/` กระบวนการทำงานจะเป็นดังนี้:

1. **เตรียมสภาพแวดล้อม:** ติดตั้ง Library ที่จำเป็นผ่าน `env` โดยใช้ `requirements.txt` และ `mim install`
2. **จัดการข้อมูล:** รันสคริปต์ `prepare_dataset.py` เพื่อแปลงภาพและจัดเตรียมลงในโฟลเดอร์ `data/slip_dataset/`
3. **ปรับแต่ง:** แก้ไขไฟล์ใน `configs/` เพื่อกำหนดจำนวนคลาสและพาธของข้อมูลให้ถูกต้อง
4. **สอนโมเดล (Train):** เรียกใช้สคริปต์จากไลบรารี โดยรัน `python library/mmsegmentation/tools/train.py configs/segformer_mit-b2.py`
5. **นำไปใช้งาน (Deploy):** โค้ดฝั่งเซิร์ฟเวอร์จะเรียกใช้ไฟล์ `latest.pth` จากโฟลเดอร์ `work_dirs/` ร่วมกับสคริปต์ `predict.py` เพื่อสแกนสลิปจริง
