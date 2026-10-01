## 2026-10-01 23:20 +07 - SegFormer Test-Case unit/integration tests (หลังเพิ่ม plot_version_results)

- Target: `model/segformer/Test-Case/test_evaluation_core.py`, `model/segformer/Test-Case/test_source_inventory.py`, `model/segformer/Test-Case/test_plot_version_results.py` (ไฟล์ใหม่)
- Command: `cd model/segformer/Test-Case && /home/panuwat/project/server/venv/bin/python -m unittest -v test_evaluation_core.py test_source_inventory.py test_plot_version_results.py`
- Result: PASS
- Summary: Total: 15 | Passed: 15 | Failed: 0 | Skipped: 0 | Duration: 0.187s
  (ชุดเดิม 6 เคส + ชุดใหม่ 9 เคส; runner `run_test_cases.sh` ขั้นที่ 1/4 เพิ่ม `test_plot_version_results.py` แล้ว)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **TestBinaryMetrics (2 เคส) — `test_evaluation_core.py`**
  - `test_metrics_are_derived_from_pixel_confusion_counts`: ส่ง target `[0,0,1,1]` กับ prediction `[0,1,1,0]` ได้ confusion `{tp:1, fp:1, fn:1, tn:1}` ตรงทุกช่อง และได้ mIoU = 1/3, mDice = 1/2, forgery_IoU = 1/3, forgery_Dice = 1/2, accuracy = 1/2, FPR = 1/2 ตรงกับสูตรใน `evaluation_core.metrics_from_confusion`
  - `test_absent_forgery_class_is_not_invented_when_both_masks_are_empty`: mask ว่างทั้งภาพต้องได้ `forgery_IoU = None` และ `forgery_Dice = None` (ไม่แต่งค่า 0) และ mIoU/mDice = 1.0
- **TestProductionStyleTiling (1 เคส) — `test_evaluation_core.py`**
  - `test_large_image_is_tiled_and_reassembled_at_original_resolution`: ภาพ 750x700 ต้องถูกตัดเป็น tile 512x512 จำนวน 4 ใบ (บันทึก shape ของ input ทั้งหมดเป็น `(1, 3, 512, 512)`) และ probability map ที่ได้ต้องมี shape `(700, 750)` พร้อมค่า 0.9 ทุกพิกเซลภายใน `rtol/atol = 1e-5` ยืนยันว่าต่อกับ `server/app/services/tiling.py` แบบเดียวกับ production
- **TestSourceInventory (3 เคส) — `test_source_inventory.py`**
  - `test_masked_dataset_has_105_complete_pairs_in_seven_categories`: สแกน `/home/panuwat/Pictures/Test-Cases/with_mask` ได้ 105 เคส พร้อม category ครบ 7 หมวด (authentic, casia, copymove, face, imd2020, inpainting, splicing) และทุกเคสมีไฟล์ภาพกับ mask อยู่จริง
  - `test_all_masks_are_binary_and_match_their_image_dimensions`: เปิด mask ทั้ง 105 ไฟล์ด้วย PIL แล้วขนาดเท่ากับภาพทุกเคส และชุดค่าสีของ mask อยู่ใน `{0, 1}` เท่านั้น
  - `test_qualitative_dataset_has_30_complete_original_manipulated_pairs`: `/home/panuwat/Pictures/Test-Cases/pairs` มี 30 คู่ เรียงจาก `pair001` ถึง `pair030` และไฟล์ original/manipulated ของทุกคู่มีอยู่จริง
- **TestVersionOrdering (1 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_versions_sort_numerically_instead_of_lexicographically`: อินพุต `["v1.0.10", "v1.0.9", "v1.0.2", "v1.0.0"]` ต้องเรียงเป็น `["v1.0.0", "v1.0.2", "v1.0.9", "v1.0.10"]` ยืนยันว่า `version_key` แยกตัวเลขเป็น tuple ไม่ใช่เทียบสตริง (ป้องกัน v1.0.10 หายไปก่อน v1.0.9 ในกราฟ)
- **TestMergeQuantitativeOverall (3 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_second_snapshot_fills_versions_missing_from_the_first`: ให้ snapshot แรกมีเฉพาะ v1.0.8 และ snapshot ที่สองมี v1.0.7 กับ v1.0.8 ผลลัพธ์ต้องมี 2 เวอร์ชันเรียง v1.0.7, v1.0.8 โดย v1.0.8 ยังคงชี้แหล่งข้อมูลเป็น snapshot แรก (ไม่ถูก snapshot ที่สองทับ) และ note ต้องมีสถานะ `verified` สำหรับเวอร์ชันที่ตรงกัน
  - `test_conflicting_metric_values_between_snapshots_are_rejected`: ให้ mDice ของ v1.0.8 ต่างกัน (87.0 กับ 91.0) ต้อง raise `ValueError` ที่ข้อความระบุฟิลด์ `mDice_percent` เป็นต้นเหตุ เพื่อไม่ให้ผสมตัวเลขจากสอง snapshot ที่ขัดกัน
  - `test_missing_snapshot_is_reported_instead_of_raising`: ชี้ snapshot ที่สองไปยังโฟลเดอร์ที่ไม่มีไฟล์ ต้องยังอ่านข้อมูลจาก snapshot แรกได้ 1 เวอร์ชัน และบันทึก note สถานะ `skipped` แทนการ crash
- **TestCategoryMatrix (1 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_matrix_has_one_row_per_category_and_one_column_per_version`: ข้อมูล 2 เวอร์ชัน × 2 หมวด (casia, authentic) ต้องได้ `groups == ["casia"]` และ `matrix == [[30.0, 31.0]]` เมื่อ `exclude_authentic=True` และได้ `matrix == [[0.1, 0.2], [1.0, 2.0]]` เมื่อรวม authentic นี่คือ regression guard ของบั๊กที่เคยทำให้ heatmap สลับแถว/คอลัมน์จนกราฟโชว์ 9 แถวแต่ป้ายแถวมีแค่ 6
- **TestMergeQuantitativeCategories (1 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_categories_from_both_snapshots_are_merged_per_version`: รวม `per_category.csv` จากสอง snapshot แล้วต้องได้ 2 แถวเรียง v1.0.7 แล้ว v1.0.8 และค่า forgery_Dice ของ v1.0.8 ต้องเป็น 75.3 ตามไฟล์ต้นทาง
- **TestLoadQualitativeResults (2 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_per_version_statistics_are_derived_from_the_pair_rows`: ไฟล์ 2 คู่ (peak 90/70 ของ manipulated, 10/20 ของ original, area เกินเกณฑ์ 1 คู่ต่อฝั่ง) ต้องได้ `pair_count = 2`, mean manipulated 80.0, mean original 15.0, max original 20.0, min manipulated 70.0 และนับคู่ที่เกิน threshold ได้ 1 และ 1 ตรงกับที่นับจากแถวจริง
  - `test_file_whose_version_column_disagrees_with_the_folder_is_skipped`: ไฟล์อยู่ในโฟลเดอร์ `v1.0.0` แต่คอลัมน์ version เป็น `v1.0.9` ต้องถูกข้ามจนไม่เหลือแถวข้อมูล และฟังก์ชันต้อง raise `ValueError` แทนการนำตัวเลขมาผสมผัง
- **TestLoadLockedResults (1 เคส) — `test_plot_version_results.py` (ใหม่)**
  - `test_locked_rows_come_from_the_manifest_expected_common_test`: manifest จำลอง 2 เวอร์ชันที่สลับลำดับในไฟล์ ต้องถูกอ่าน `expected_common_test` มาเรียงตามเลขเวอร์ชัน (v1.0.0 ก่อน v1.0.1) และได้ mDice 51.42 / forgery_Dice 2.22 ตรงตามไฟล์ พร้อมคืนค่า `dataset.id` เป็น locked-set

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- ไม่มีข้อผิดพลาด (0 Failed) ในผลรันสุดท้าย

หมายเหตุการทดสอบเพิ่มเติมรอบนี้ (ไม่ใช่ failed test):
- ระหว่างพัฒนา `plot_version_results.py` พบบั๊กจริง 1 จุดที่ทำให้กราฟผิด แล้วแก้และป้องกันด้วย `test_matrix_has_one_row_per_category_and_one_column_per_version`: `category_matrix` เดิมสร้างแถวตามเวอร์ชันแล้วสลับกับป้ายแถวที่เป็นหมวด ทำให้ heatmap มี 9 แถวข้อมูลแต่ป้ายแถวแค่ 6 รายการ แก้เป็นหนึ่งแถวต่อหนึ่งหมวดและหนึ่งคอลัมน์ต่อหนึ่งเวอร์ชัน พร้อมแก้ `chart_category_lines` ที่อ่านเมทริกซ์ผิดแนว
- ยืนยันด้วยตาแล้วว่าค่าในกราฟตรงกับไฟล์ต้นทาง เช่น Forgery Dice หมวด copymove ของ v1.0.5 = 3.7, v1.0.6 = 65.9, v1.0.7 = 74.6 และ v1.0.8 = 60.9 ตรงกับ `per_category.csv` และกับตัวเลขใน `Test-Case/RESULTS.md`
- การรันเป็น unit/integration test เท่านั้น ยังไม่ได้รัน `run_test_cases.sh` เต็มรูปแบบ เพราะขั้นที่ 3 และ 4 ต้องรัน ONNX inference จริงบน 105 ภาพและ 30 คู่ภาพต่อเวอร์ชัน ซึ่งผู้ใช้ไม่ได้สั่งให้รันซ้ำ และผลลัพธ์เหล่านั้นถูกใช้เป็นข้อมูลตั้งต้นของกราฟอยู่แล้ว
