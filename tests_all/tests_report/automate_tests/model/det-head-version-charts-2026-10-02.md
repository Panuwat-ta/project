## 2026-10-02 01:30 +07 - Det-Head version comparison diagnostics (20 heads, Test-Cases 176 ภาพ)

- Target: `model/segformer/Det-Head/eval_det_diagnostics.py` (แก้ `load_any_det` ให้รองรับ `patch_topk`), `model/segformer/Det-Head/plot_det_versions.py` (ใหม่), `model/segformer/Det-Head/test_plot_det_versions.py` (ใหม่ 4 เคส)
- Command: `./venv/bin/python Det-Head/eval_det_diagnostics.py --config configs/segformer_mit-b2-v11.py --checkpoint work_dirs/v1.0.6/best_mIoU_iter_195000.pth --head det1=... (20 heads) --sets camera9,chatshot2,testcases --out-dir Det-Head/diagnostics_det_versions_2026-10-02 --threshold 0.5 --batch-size 8 --device cuda` และ `../venv/bin/python -m unittest -v test_plot_det_versions.py`
- Result: PASS
- Summary: Total: 24 | Passed: 24 | Failed: 0 | Skipped: 0
  (diagnostics 20/20 heads ครบทุก set + unit test 4/4; เวอร์ชันที่ไม่มี test-case มาก่อนถูกรันใหม่บนภาพ `/home/panuwat/Pictures/Test-Cases` ทั้งหมดในรอบเดียวด้วย seg backbone เดียวกัน)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Diagnostics run — testcases 165 ภาพ (20/20 heads)**
  - พฤติกรรมที่ผ่าน: ทุก head ถูกสกัด feature จาก seg backbone เดียวกันในรอบเดียว (extract_feat ครั้งเดียวต่อภาพ แล้ว forward 20 heads) บน GPU ได้ per-set CSV 60 ไฟล์และ `diagnostics.json` พร้อม confusion + by_dataset ครบ ผลลัพธ์: det4c ดีสุด accuracy 88.5% ตามด้วย det4a 87.9%, det6a/det7b 87.3%, det1 ต่ำสุด 80.6%; หมวด face ได้ 100% ทุก head ส่วน inpainting อ่อนสุด (53–80%)
  - เงื่อนไขที่ผ่าน: with_mask 105 ภาพ (authentic 15 ภาพ label 0 + 6 หมวด 90 ภาพ label 1) และ pairs 60 ภาพ (originals 30 label 0 + manipulated 30 label 1) ครบ 165 ไฟล์จริงบนดิสก์ (สคริปต์ raise ถ้าไฟล์หาย)
- **Diagnostics run — camera9 9 ภาพ (20/20 heads)**
  - พฤติกรรมที่ผ่าน: ภาพกล้องจริง label 0 ทั้งหมด วัด specificity (ไม่ false alarm): det7b ได้ 88.9% (8/9) สูงสุด ตามด้วย det5a_pre 66.7% ส่วน det1/det5a/det5g/det6a ได้ 11.1% (1/9) ยืนยันทิศทางเดียวกับบันทึกเดิมใน `det_head_variants.py` ที่ det7b นำบน camera9
- **Diagnostics run — chatshot2 2 ภาพ (20/20 heads)**
  - พฤติกรรมที่ผ่าน: รันครบทั้ง 20 heads ได้ accuracy 0/2 สำหรับ 17 heads, 1/2 สำหรับ det5f กับ det7a และ 2/2 สำหรับ det7b; ตามเอกสารในหัวไฟล์ n=2 ใช้ดูแนวโน้มเท่านั้น ไม่ใช้ตัดสิน
- **Unit tests — `test_plot_det_versions.py` (4/4)**
  - `test_known_heads_follow_head_order_and_unknown_heads_go_last`: อินพุต `["det7b", "det1", "zzz_custom"]` ต้องเรียงเป็น `["det1", "det7b", "zzz_custom"]` ยืนยันว่า head ที่รู้จักเรียงตาม `HEAD_ORDER` และ head ใหม่ที่ไม่รู้จักไปอยู่ท้ายโดยไม่หาย
  - `test_empty_heads_are_rejected`: diagnostics ที่ไม่มี head ต้อง raise `ValueError` แทนการสร้างกราฟว่าง
  - `test_means_are_computed_per_label_and_per_dataset`: CSV จำลอง 2 แถว (authentic 0.2, casia 0.8) ต้องได้ authentic_mean 0.2, manipulated_mean 0.8, n_authentic/n_manipulated 1/1 และ dataset_mean ตรงตามหมวด
  - `test_head_order_constant_covers_every_expected_variant`: `HEAD_ORDER` ต้องมี 20 ตัว เริ่ม det1 จบ det7b ตรงกับจำนวน checkpoint จริง

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- ไม่มีข้อผิดพลาด (0 Failed) ในผลรันสุดท้าย

หมายเหตุการทดสอบเพิ่มเติมรอบนี้ (ไม่ใช่ failed test):
- ก่อนรันพบว่า `load_any_det` รับ checkpoint `patch_topk` (det5b) ไม่ได้ เพราะอ่าน `pos_embed` จาก state_dict ทั้งที่ head ชนิดนี้ไม่มี key นั้น (มีแค่ `scorer`) แก้โดยส่งไป `load_det5` โดยตรงตาม `det_arch` ที่บันทึกใน meta แล้วตรวจว่าโหลดครบทั้ง 20 heads พร้อมนับพารามิเตอร์ได้ (det1 1,025 ถึง det7a/det7b 401,665)
- กราฟ `plot_det_versions.py` 6 ภาพ + `report.html` ตรวจด้วยตาแล้วว่าค่าตรงกับ stdout ของรอบรัน (det4c 88.5, det7b camera9 88.9, det5a_pre chatshot threshold ฯลฯ) และฝังภาพไว้ในไฟล์เดียวเปิดออฟไลน์ได้
- ไม่ได้รัน set pilot11 เพราะไฟล์อยู่ใน `server/uploads` ไม่ใช่ `/home/panuwat/Pictures/Test-Cases` ตามที่ผู้ใช้สั่ง และเป็นข้อมูลทดสอบที่อาจถูกล้างแล้ว
