# โครงสร้างโฟลเดอร์สำหรับงานพัฒนาโมเดล AI (AI Model Development Structure)

โฟลเดอร์ `model/` ถูกจัดโครงสร้างโดยรวมศูนย์การทำงานไว้ที่ `segformer/` ซึ่งแยก "ไลบรารีภายนอก" ออกจาก "โค้ดแอปพลิเคชัน" อย่างชัดเจน เพื่อความสะดวกในการดูแลรักษา การเทรน และนำไปเชื่อมต่อกับ FastAPI

## โครงสร้างโฟลเดอร์แบบละเอียด (Detailed Directory Tree)

```text
/home/panuwat/project/model/
│
├── segformer/                # [แอปหลัก] เทรน/export/test SegFormer
│   ├── configs/              # คอนฟิกเฉพาะโปรเจกต์ (segformer_mit-b2.py, v1-v9)
│   │                         # - num_classes = 2 (background/forgery)
│   │                         # - v8/v9 = พร้อมเทรนรอบถัดไป (balanced multi-dataset)
│   ├── library/
│   │   └── mmsegmentation/   # โค้ดต้นฉบับ OpenMMLab (ห้ามแก้ไข)
│   ├── work_dirs/            # ผลเทรนรายเวอร์ชัน (สร้างโดย train.sh, auto-versioning)
│   │   ├── segformer_v1.0.0(test-model)/, segformer_v2.0.0(test-model)/
│   │   ├── v1.0.0/           # Production: best_mIoU_iter_112000.pth + .onnx
│   │   └── v1.0.1/ ... v1.0.4/  # fine-tune ต่อ, v1.0.4 deprecated (forgetting)
│   │       ├── <run>/vis_data/scalars.json  # log เทรน (JSON-lines)
│   │       ├── best_mIoU_iter_*.pth / iter_*.pth
│   │       └── *_dynamic.onnx (+ .data)
│   ├── report/               # รายงาน + สคริปต์พล็อต
│   │   ├── reportmodel.md    # สรุปผล/benchmark/root-cause ทุกรุ่น
│   │   ├── plot_training.py  # พล็อต log v1.0.0-v1.0.4 (รันด้วย `model/segformer/.venv/bin/python`)
│   │   └── figs/             # PNG ที่ส่งออก
│   ├── tests_model/img/      # ภาพตัวอย่างทดสอบ (test.jpg) + test.sh
│   ├── prepare_dataset/          # pipeline เดียว: clean_dataset.py + README
│   │   │                         # USB(/run/media/panuwat/USB/data) -> ~/Pictures/dataset
│   │   │                         # PNG lossless + stratified split + manifest.json
│   ├── train.sh              # เทรน (auto-version, --load-from/--no-load)
│   ├── export_onnx_dynamic.py# export ONNX dynamic axes
│   ├── predict_test.py       # inference + heatmap overlay
│   ├── requirements.txt venv/ .gitignore
│   └── README.md error.md test.jpg
│
├── surya/                    # Surya OCR (HF_HOME) — hub/vikp/surya_det3+rec2
├── Qwen2.5-1.5B/             # Qwen XAI (qwen2.5-1.5b-instruct-q4_k_m.gguf)
├── README.md                 # เอกสารอ้างอิงกลางของโมเดลทั้งหมด
└── doc.md                    # ไฟล์นี้
```

## กระบวนการทำงาน (Workflow)

หากคุณอยู่ที่พาธ `project/model/segformer/` กระบวนการทำงานจะเป็นดังนี้:

1. **เตรียมสภาพแวดล้อม:** ใช้ `venv/` ติดตั้งผ่าน `requirements.txt` (ปัญหา mmcv ดู `error.md`)
2. **จัดการข้อมูล:** รัน `prepare_dataset/clean_dataset.py` (ดู `prepare_dataset/README.md`) แปลงดิบจาก USB เป็น clean ใน `~/Pictures/dataset`
3. **ปรับแต่ง:** แก้ไฟล์ใน `configs/` (num_classes=2, dataloader paths, LR แยก backbone/head)
4. **สอนโมเดล (Train):** รัน `./train.sh [--load-from <pth> | --no-load]` (auto-versioning ไป `work_dirs/vX.Y.Z/`)
5. **ทดสอบ:** (เมื่อ cwd คือ `model/segformer/`) รัน `./tests_model/test.sh` หรือ `python predict_test.py --checkpoint ... --image ...` ดู heatmap
6. **นำไปใช้งาน (Deploy):** export ด้วย `export_onnx_dynamic.py` แล้วชี้ `ONNX_MODEL_PATH` ใน `server/.env` ไปที่ `.onnx` ตัวใหม่
