# ผลทดสอบ v13 หลังเทียบ config ทุกเวอร์ชัน — 2026-09-23

- Target: model/segformer/tests_model/report/test_training_config_v13.py
- Command: `NO_ALBUMENTATIONS_UPDATE=1 PYTHONDONTWRITEBYTECODE=1 /home/panuwat/project/model/segformer/venv/bin/python /home/panuwat/project/model/segformer/tests_model/report/test_training_config_v13.py -v`
- Result: PASS
- Summary: Total: 10 | Passed: 10 | Failed: 0 | Skipped: 0 | Duration: 2.944 seconds

## 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน

1. test_hand_calculated_confusion_and_core_matches_official_metric: fixture CASIA ได้ Dice=50%, FPR=50%; authentic FPR=25%, core FPR=200/9%, macro Dice=75%; core mIoU/mDice/aAcc/mAcc ตรง IoUMetric เดิม
2. test_new_domain_size_cannot_change_core_checkpoint_scores: เพิ่มภาพ source ใหม่ 20 ภาพแล้ว core mIoU/mDice/macro/FPR ไม่เปลี่ยน แต่ metric ของ source ใหม่เปลี่ยนตาม prediction
3. test_macro_weights_sources_equally_not_by_image_count: เพิ่มภาพ CASIA fixture ซ้ำ 9 ภาพ macro ยัง 75% เพราะให้น้ำหนักราย source เท่ากัน
4. test_ignore_pixels_and_perfect_authentic_are_not_forgery_score: พิกเซล 255 ไม่เพิ่ม FP, perfect authentic มี FPR=0 และ undefined Dice=NaN โดยไม่เข้าค่า macro
5. test_missing_or_unknown_sources_fail_loudly: source หายหรือ path ไม่ตรง root ทำให้ ValueError ตามที่คาด
6. test_ambiguous_roots_rejected: roots ซ้อนกันถูกปฏิเสธเพื่อไม่จัดหมวดผิด
7. test_evaluate_clears_results_and_retains_source_identity: สลับลำดับ samples ยังได้ macro=75% และ evaluate ล้าง buffer แล้ว
8. test_config_dump_roundtrip_evaluator_and_checkpoint_hook: dump/reload สำเร็จ, registry สร้าง metric ได้, 9 validation roots/7 core roots, official test IoUMetric เดิม และ checkpoint hook รับ metric ทั้งสองที่มีในผลจริง
9. test_runtime_augmentation_keeps_authentic_background_and_binary_masks: รัน pipeline 9 แหล่งบน synthetic image/mask; output 3×512×512, labels อยู่ใน {0,1}, authentic ยังคง 0 ทั้งภาพและ CopyPaste อยู่เฉพาะ scope ที่กำหนด
10. test_cpu_forward_backward_and_real_optimizer_groups: build MiT-B2 จริง, loss/gradients ของ backbone/head finite, LR ของ parameter groups จริงตรง backbone=1e-5/head=1e-4 และ normalization/bias decay=0

## 2. รายการที่ไม่ผ่านและสาเหตุ

ไม่มีข้อผิดพลาด (0 Failed)

ข้อจำกัด: synthetic fixtures ใช้ตรวจโค้ด ไม่ใช่ผลประเมินความแม่นยำ ใช้ CPU BN/OptimWrapper แทน SyncBN/AMP ใน test และปิด pretrained initialization เพื่อไม่ดาวน์โหลด ไม่ได้วัด CUDA AMP, full batch VRAM, distributed multi-process หรือโหลด dataset จริง เพราะ /run/media/panuwat/USB/dataset ไม่พบ

ผล staging ก่อนติดตั้ง: 10/10 ผ่านใน 3.118s; รอบด้านบนเป็นการรันซ้ำจากไฟล์ที่ติดตั้งในโปรเจกต์จริงแล้ว ตรวจไฟล์ติดตั้งตรงกับ staging และ Python syntax ผ่าน; git diff --check ผ่าน
