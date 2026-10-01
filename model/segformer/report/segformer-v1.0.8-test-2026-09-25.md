# รายงานทดสอบ SegFormer v1.0.8

วันที่ทดสอบ: 25 กันยายน 2569  
เครื่องทดสอบ: `panuwat@linux-ac`  
สถานะ: **ยังไม่ผ่านเกณฑ์แทน v1.0.6**

## ข้อสรุป

เลือก `best_mIoU_iter_207500.pth` จาก validation ก่อนเปิด locked test และประเมินจริงทั้ง PyTorch locked test กับ ONNX บนชุดภาพมาตรฐาน 105 ภาพ ผล locked test สูงกว่า v1.0.6 เล็กน้อย แต่ ONNX บนภาพ 105 ภาพถอยชัดเจน โดยเฉพาะ Forgery Dice และ false positive rate (FPR) จึงยังไม่ควร deploy v1.0.8 แทน v1.0.6

ทดสอบ `best_core_macro_forgery_dice_iter_250000.pth` บน ONNX local 105 ภาพเพิ่มเติมในฐานะ candidate เชิงสำรวจ ผลยังไม่ผ่านเกณฑ์เช่นกัน **ไม่ได้ใช้ local 105 ภาพเลือก checkpoint สำหรับ locked test** และไม่ได้รัน locked test สำหรับ checkpoint ตัวนี้

## ผลเทียบรุ่น

คะแนนทั้งหมดเป็นเปอร์เซ็นต์; `—` หมายถึงไม่ได้รันทดสอบนั้น

| โมเดล/checkpoint | Locked mIoU | Locked mDice | Local mIoU (105 ภาพ) | Local mDice | Local Forgery Dice | Local FPR | Local IMD2020 Forgery Dice |
|---|---:|---:|---:|---:|---:|---:|---:|
| v1.0.6 / best mIoU 195k | 94.83 | 97.29 | 83.14 | 90.17 | 81.90 | 0.83 | 42.13 |
| v1.0.7 / best mIoU 240k | 94.96 | 97.36 | 81.13 | 88.78 | 79.34 | 1.08 | 49.62 |
| **v1.0.8 / best mIoU 207.5k** | **94.99** | **97.38** | **78.72** | **87.06** | **76.27** | **1.86** | **47.73** |
| v1.0.8 / best core macro Dice 250k | — | — | 78.86 | 87.19 | 76.61 | 2.35 | 47.72 |

เทียบ v1.0.6 กับ checkpoint หลัก: locked mDice เพิ่ม 0.09 จุด แต่ local mDice ลด 3.11 จุด, local Forgery Dice ลด 5.63 จุด และ local FPR เพิ่ม 1.03 จุดเปอร์เซ็นต์ ผลที่สวนทางกันแสดงว่า locked benchmark เพียงชุดเดียวไม่พอใช้ตัดสิน production robustness

## ประเมินเกณฑ์ v13

| เกณฑ์ที่ระบุไว้ใน config | ผล v1.0.8 best mIoU | สถานะ |
|---|---:|---|
| Locked mDice ≥97.29% | 97.38% | ผ่าน |
| Local mDice ≥90.17% | 87.06% | ไม่ผ่าน |
| Local IMD2020 Forgery Dice >50% | 47.73% | ไม่ผ่าน |
| Local overall FPR ≤1.0% | 1.86% | ไม่ผ่าน |

สคริปต์ `evaluate_with_masks.py` รายงานว่า *release gate passed* เพราะรอบนี้กำหนด gate พื้นฐาน mDice ≥85% (`87.06%`) ผลนี้ **ไม่ใช่การผ่าน promotion criteria ของ v13** และ `run_test_cases.sh` ยังมี gate รุ่นเก่าที่ผูก v1.0.5 จึงใช้คำสั่งประเมินแยกพร้อม `--release-version v1.0.8` และ output directory แยก

## จุดที่ถอยรายหมวดบน local 105 ภาพ

| หมวด | v1.0.6 Forgery Dice | v1.0.8 best mIoU Forgery Dice | v1.0.8 best macro Forgery Dice |
|---|---:|---:|---:|
| CASIA | 83.92 | 75.25 | 81.02 |
| CopyMove | 65.86 | 60.91 | 62.30 |
| Face | 98.89 | 92.18 | 88.91 |
| IMD2020 | 42.13 | 47.73 | 47.72 |
| Inpainting | 84.79 | 76.46 | 78.86 |
| Splicing | 91.13 | 81.17 | 80.25 |

ภาพ authentic ทั้ง 15 ภาพมี FPR 0.64% สำหรับ best mIoU และ 0.71% สำหรับ best macro เทียบกับ 0.01% ของ v1.0.6; จึงมีความเสี่ยงแจ้งภาพจริงผิดมากขึ้น ใน 92 ภาพที่ทั้งสองรุ่นมี Forgery Dice รายภาพนิยามได้ v1.0.8 best mIoU ชนะ v1.0.6 จำนวน 22 ภาพ เสมอ 17 และแพ้ 53 ภาพ; ยืนยันว่าใช้ case IDs เดียวกันครบ 105 ภาพ

## การรันและความถูกต้องของไฟล์

- Locked PyTorch test ของ `best_mIoU_iter_207500.pth`: **2,504/2,504 batches จบ**, mIoU 94.99%, mDice 97.38%, Forgery IoU 90.56%, Forgery Dice 95.04%; บันทึกใต้ `work_dirs/v1.0.8/test_eval/locked_miou_207500/` บน linux-ac
- Export ONNX checkpoint หลักและ checkpoint แบบ macro สำเร็จ โดย `onnx.checker.check_model` ผ่านทั้งสองไฟล์; เก็บใน `work_dirs/v1.0.8/` แยกชื่อ
- ONNX contract suite ของ checkpoint หลัก **3/3 ผ่าน**: model/external weights มีจริง, dynamic input/output metadata ถูกต้อง, และ inference finite/repeatable บน 2 ขนาด
- PyTorch ↔ ONNX parity ของ checkpoint หลักผ่าน input 256×256 และ 320×448; logits ต่างสูงสุด 0.00000477 และ 0.00000435 ตามลำดับ, argmax mismatch 0% ทั้งคู่
- Local quantitative ONNX ใช้ภาพ/mask **105 คู่ครบ 7 หมวด**, production-style tiling 512/overlap 64 และ threshold 0.5; checkpoint ทั้งสองประเมินแยก output โดยไม่เขียนทับ combined report เดิม
- Local inventory/metric/tiling unit tests **6/6 ผ่าน** รวม image/mask binary และขนาดตรงกัน
- Qualitative ONNX **30/30 คู่สร้างภาพได้** ที่ display threshold 0.4 ไม่มี ground-truth mask จึงไม่ใช่คะแนน accuracy; 8 คู่มีพื้นที่เกิน threshold ในภาพ manipulated น้อยกว่าภาพ original ตัวอย่าง `pair016`: original 5.76%, manipulated 2.53% ตรวจภาพตัวอย่างแล้วเห็น heatmap ในภาพ original ด้วย

## ขอบเขตการตีความ

คะแนน locked และ local มาจากคนละ distribution และคนละ inference protocol; เปรียบเทียบแต่ละรุ่น **ภายในชุดเดียวกัน** เท่านั้น จำนวน batches และ root ของ locked test ตรงกับรุ่นก่อน แต่ไม่มี dataset fingerprint ที่เก็บไว้ก่อนหน้า จึงยืนยันไม่ได้ว่า bytes ของข้อมูลไม่เปลี่ยนตั้งแต่การทดสอบรุ่นเก่า

Local 105 ภาพเคยใช้วิเคราะห์เพื่อออกแบบ v13 แล้ว จึงเป็น regression set ที่มีประโยชน์แต่ไม่ใช่ untouched holdout สำหรับอ้างความสามารถกับภาพใหม่ใน product รอบนี้ไม่ได้สร้างชุด holdout จากแหล่งภาพใหม่ และยังไม่ได้ทดสอบผ่าน product API หรือ GPU ONNX worker จริง

ไฟล์ทดสอบอยู่ใต้ `work_dirs/v1.0.8/test_eval/` บน linux-ac; canonical `tests_model/evaluation_manifest.json`, `Test-Case/output/` และ production model ไม่ได้เปลี่ยน การตัดสิน deployment: **คง v1.0.6**; หากทดลองรุ่นถัดไปให้ตรวจ FP บนภาพ authentic และ regression ใน CASIA/Face/Splicing/Inpainting ก่อนใช้ locked test อีกครั้ง

## Provenance

- Config: `configs/segformer_mit-b2-v13.py`, SHA256 `ac7c8993eb736c4d02f70883300431d0d10664fd8d06e0ef4c0bdbf22f5f840c`
- Checkpoint ที่เลือก: `best_mIoU_iter_207500.pth`, SHA256 `2142f70bbfbc6074507366c75208a70ba7be5c7b7de973e87a86ab4f788e2310`
- ONNX: `segformer_v1_0_8_dynamic.onnx`, SHA256 `2b4218bbcdefaa1766592c4e90a6674b4a2fd6acce91a80b45b2a6b0e7a0f950`; external `.onnx.data`, SHA256 `73d3e487307a2cfd1338824eb32da0c2c37582e0a27941ed72a7323b0599ae4d`
- Locked run ID: `20260925_232201`; training run ID: `20260923_184557`
