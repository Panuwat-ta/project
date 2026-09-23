# Config v13 สำหรับ candidate v1.0.8

วันที่ตรวจ: 2026-09-23

พบ config ที่สร้างไว้แล้วจากงานก่อนหน้าใน `/home/panuwat/project/model/segformer/configs/segformer_mit-b2-v13.py` รอบนี้ตรวจสอบการโหลดและ pipeline เพิ่มเติม ไม่ได้สร้าง v14 ซ้ำหรือเปลี่ยน hyperparameter ของ v13
สำเนา config ใน outputs ต้องใช้แทนไฟล์ชื่อเดียวกันในโฟลเดอร์ configs ของโปรเจกต์ เพราะอ้างอิง library และ forgery_aug.py ของโปรเจกต์ ไม่ใช่ไฟล์ standalone

## ค่าที่เตรียมไว้

| รายการ | v12 | v13 |
|---|---|---|
| CASIA repeat | 4 | 5 |
| CopyPaste probability | 0.30 | 0.20 |
| CopyPaste sources | ทุก forged source | copymove, imd2020, inpainting |
| AIForge repeat | 10 | 6 |
| RealText repeat | 6 | 4 |
| IMD2020 repeat | 3 | 3 |
| แหล่งข้อมูล train / validation / test | 9 / 9 / 7 | 9 / 7 / 7 |
| Seed | 43 | 44 |

คง MiT-B2 pretrained, CE + Dice loss, AdamW, backbone LR 1e-5 / head LR 1e-4, AMP, batch 8 และ gradient accumulation 2 (effective batch 16 บน GPU เดียว), budget 250,000 iterations เลือก best checkpoint ด้วย validation mIoU

เหตุผลอิงรายงาน `model/segformer/report/segformer-test-audit-2026-09-23.md`: v1.0.7 มี CASIA Forgery Dice ลดลง 11.35 จุด และ overall FPR เพิ่มจาก 0.83% เป็น 1.08% ขณะที่ CopyMove, IMD2020 และ Inpainting ดีขึ้น การปรับ v13 เป็นสมมติฐานทดลอง ยังไม่มี ablation ยืนยันว่า CopyPaste หรือ sampling เป็นสาเหตุ และไม่มีผลเทรนที่รับประกันว่าจะดีกว่า v1.0.6

## การเลือกและประเมินโมเดล

เลือก checkpoint และปรับ threshold ด้วย validation เท่านั้น ประเมิน AIForge/RealText validation แยกเพิ่มเติม เพราะไม่ได้ร่วมเลือก best checkpoint ใน config นี้ การเปลี่ยน seed พร้อมหลายพารามิเตอร์ทำให้ผลรอบเดียวไม่สามารถแยกสาเหตุ improvement/regression ได้

เป้าหมายเดิมที่ระบุใน config: local mDice >= 90.17%, locked mDice >= 97.29%, local IMD2020 Forgery Dice > 50%, local overall FPR <= 1.0% เป้าหมายเหล่านี้เป็นข้อความกำกับ ไม่ใช่ gate ที่ config บังคับอัตโนมัติ ต้องประเมินกับ pipeline/threshold เดียวกับ baseline และตรวจครบก่อน promote

Locked test ใช้หลังเลือก checkpoint เสร็จเท่านั้น ชุด local ที่เคยใช้วิเคราะห์ regression เป็น regression set ไม่ใช่หลักฐาน generalization ที่เป็นอิสระ ควรยืนยันกับ holdout ใหม่ที่ยังไม่เคยใช้ตัดสินใจปรับ config ก่อนสรุปว่าโมเดลดีที่สุด

## ผลตรวจรอบนี้

- Python compile, MMEngine Config.fromfile และ compile cfg.pretty_text ผ่าน
- สร้าง Compose pipeline จริงผ่านครบ 23 รายการ: train 9, validation 7, test 7
- ยืนยัน CopyPaste p=0.2 เฉพาะ copymove / imd2020 / inpainting; authentic ไม่มี CopyPaste
- ยังไม่พบ DATA_ROOT และ image directories ของทุก source จึงยังไม่ได้โหลดข้อมูลจริงหรือรัน train/forward/backward
- มีคำเตือนตรวจเวอร์ชัน Albumentations ผ่านเครือข่ายไม่ได้, optional MultiScaleDeformableAttention ของ mmcv-lite และ reduce_zero_label deprecation; config/pipeline checks จบด้วย exit code 0

## คำสั่งเทรน

หลัง mount dataset ให้ตรง DATA_ROOT และตรวจว่ามี images/annotations ใน train, val, test ตามแต่ละ source:

```bash
cd /home/panuwat/project/model/segformer
./train.sh --config configs/segformer_mit-b2-v13.py --no-load
```

--no-load เริ่มรอบใหม่จาก pretrained backbone ตาม config ไม่ใช่ resume checkpoint v1.0.7 สคริปต์เลือกเลข work_dirs อัตโนมัติ ปัจจุบันมีถึง v1.0.7 จึงคาดว่าจะเป็น v1.0.8 หากไม่มีรอบอื่นสร้างเวอร์ชันเพิ่มก่อน
