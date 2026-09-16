# ผลตรวจ config SegFormer v11

- เวลา: 2026-09-15 16:28 +07
- Target: `model/segformer/tests_model/report/test_training_config_v11.py`
- Command (จาก project root): `NO_ALBUMENTATIONS_UPDATE=1 model/segformer/venv/bin/python model/segformer/tests_model/report/test_training_config_v11.py -v`
- Result: PASS
- Summary: Total 6 | Passed 6 | Failed 0 | Skipped 0 | Duration 4.464 seconds

## รายการที่ผ่านและเงื่อนไขที่ตรวจ

1. `test_fresh_initialization_and_serialization`: Config.fromfile รวม base ได้, load_from เป็น None, resume เป็น False, backbone ชี้ MiT-B2 และ config ที่ serialize/อ่านกลับคง model กับ train_dataloader เดิม
2. `test_validation_and_test_protocol_unchanged`: validation/test dataloader, evaluator, pipeline และ model.test_cfg เท่ากับ v10
3. `test_repeat_factors_and_authentic_crop`: แต่ละแหล่งชี้ images/train, repeat factors ตรงที่กำหนด, authentic crop ใช้ cat_max_ratio 1.0 และหมวดตัดต่อใช้ 0.99
4. `test_real_optimizer_parameter_groups`: ตรวจพารามิเตอร์จริงทั้งโมเดล ไม่มีตกหล่น, backbone LR 1e-5/head LR 1e-4, normalization และ bias decay 0, น้ำหนักอื่น decay 0.01
5. `test_training_pipeline_on_each_real_source`: ภาพ train จริงแหล่งละหนึ่งภาพจากทั้ง 7 แหล่งผ่าน pipeline, input เป็น [3,512,512], mask เป็น [1,512,512] และ labels อยู่ใน {0,1}
6. `test_finite_loss_and_backward_on_synthetic_fixture`: โมเดลบน CPU คำนวณ CE และ Dice จาก synthetic input [2,3,64,64] ได้, loss และ gradient ของทุกพารามิเตอร์ finite

## รายการที่ไม่ผ่านและข้อจำกัด

ไม่มีข้อผิดพลาด (0 Failed)

มี warning ของ environment เดิมเกี่ยวกับ MultiScaleDeformableAttention ที่ไม่ได้ใช้ใน
MiT-B2, คำแนะนำ single-channel binary output และ deprecation ของ reduce_zero_label
ทั้งหกกรณีทดสอบยังผ่าน

ไม่ได้โหลด pretrained checkpoint, รัน CUDA AMP หรือวัด VRAM ของ batch 8
forward/backward ใช้ eval mode เพื่อให้ SyncBN ทำงานบน CPU ได้ ผลนี้ยืนยันความเข้ากันได้ของ config
และ gradient เท่านั้น ยังไม่มีผล accuracy/mIoU/mDice ของโมเดล v11 หลังเทรน

## ตรวจยืนยันซ้ำ — 2026-09-15 16:34 +07

ตรวจไฟล์ v11 ที่มีอยู่ใน workspace ด้วยคำสั่งเดิม: **6 passed / 0 failed**
ระยะเวลา unittest 3.985 วินาที ยังไม่ได้เรียก train.sh หรือเริ่ม training run

นับไฟล์ images/train จริงเพื่อยืนยันฐานของ repeat factors:

| แหล่งข้อมูล | ภาพ train ไม่ซ้ำ | Repeat | รายการหลัง repeat |
|---|---:|---:|---:|
| casia | 8,913 | 5 | 44,565 |
| authentic | 85,130 | 1 | 85,130 |
| splicing | 76,500 | 1 | 76,500 |
| inpainting | 17,916 | 3 | 53,748 |
| copymove | 13,106 | 4 | 52,424 |
| face | 57,308 | 1 | 57,308 |
| imd2020 | 26,499 | 2 | 52,998 |

รวม 422,673 รายการหลัง repeat; จำนวนนี้แสดงความถี่ sampling ไม่ใช่จำนวนภาพใหม่
ผลผ่านยืนยัน config merge, parameter groups และ pipeline ตามรายละเอียดข้างต้น
ยังต้องประเมินคุณภาพหลังเทรนบน validation และยังไม่ได้ตรวจ CUDA/AMP หรือ peak VRAM
