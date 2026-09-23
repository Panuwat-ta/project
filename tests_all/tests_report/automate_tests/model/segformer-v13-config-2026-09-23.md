# ผลตรวจ config v13 — 2026-09-23

- Target: model/segformer/configs/segformer_mit-b2-v13.py
- Command: รัน inline Python ด้วย model/segformer/venv/bin/python, PYTHONDONTWRITEBYTECODE=1 และ PYTHONPATH=/home/panuwat/project/model/segformer โดย compile source, Config.fromfile, compile cfg.pretty_text, register_all_modules และ Compose ของแต่ละ dataset pipeline
- Result: PASS เฉพาะ config/pipeline smoke check
- Summary: Total: 1 script | Passed: 1 | Failed: 0 | Skipped: 0 | Duration: 5.82 seconds (รวมคำสั่งอ่านเอกสารใน invocation เดียวกัน)

## 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน

Python compile ของ source และ cfg.pretty_text ไม่เกิด exception; Config.fromfile รวม inherited config สำเร็จ; Compose สร้าง transform ทุกตัวจาก registry จริงครบ train 9 + val 7 + test 7 = 23 pipelines โดยไม่มี exception; process exit 0

ค่าที่แสดงจาก config: CopyPaste p=0.2 เฉพาะ copymove, imd2020, inpainting; repeat CASIA=5, AIForge=6, RealText=4; AmpOptimWrapper, batch=8, accumulation=2, max_iters=250000, save_best=mIoU

## 2. รายการที่ไม่ผ่านและสาเหตุ

ไม่มีข้อผิดพลาดในการโหลด config/pipeline (0 Failed)

ข้อจำกัดด้าน environment: DATA_ROOT ไม่มีอยู่จริง และ images directories ทั้ง 23 รายการตรวจได้ False จึงยังไม่ทดสอบโหลดภาพ, dataset integrity, GPU memory, forward/backward หรือ training quality ไม่ถือว่า dataset/training readiness ผ่าน

คำเตือนที่พบ: Albumentations ตรวจ version ผ่าน network ไม่ได้, optional MultiScaleDeformableAttention ไม่พร้อมใน mmcv-lite และ reduce_zero_label deprecation ทั้งหมดไม่ทำให้ smoke check หยุด
