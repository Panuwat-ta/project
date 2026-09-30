## 2026-09-29 07:05 +07 - SegFormer v14 tiled-validation hook และ test suite

- Target: `model/segformer/tiled_val.py` (ใหม่), `model/segformer/configs/segformer_mit-b2-v14.py`, `model/segformer/tests_model/report/test_tiled_val.py` (ใหม่)
- Command: `NO_ALBUMENTATIONS_UPDATE=1 PYTHONDONTWRITEBYTECODE=1 venv/bin/python tests_model/report/test_tiled_val.py`
- Result: PASS
- Summary: Total: 38 | Passed: 38 | Failed: 0 | Skipped: 0 | Duration: 8.4s
  (จำนวนเทสต์เพิ่มจาก 37 เป็น 38 หลังเพิ่มเคส fail-soft จาก real-Runner smoke test)

เพิ่มเติมชุดทดสอบเดิมที่รันเพื่อยืนยันว่าไม่มี regression:
- `tests_model/report/test_training_config_v13.py` → 10/10 ผ่าน (3.3s)
- `Test-Case/test_evaluation_core.py` → 3/3 ผ่าน (0.06s)
- `git diff --check` → clean

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **ProductionParityTests::test_parity_exact_across_sizes_and_axes**
  - พฤติกรรมที่ผ่าน: `tiled_val.tiled_forgery_probability` คืนค่า probability map ที่ตรงกับ `server/app/services/tiling.py::tile_inference` (โค้ด production ที่ import มาตรงๆ ไม่ได้แก้) ทดสอบ 6 ขนาดภาพ (512x512, 640x480, 480x640, 700x900, 300x700, 1368x2000) คูณ 2 แกน ใช้ segmentor stub ที่คืนค่า ramp ตามตำแหน่งเพื่อเปรียบเทียบ **ตำแหน่งของการ crop** ไม่ใช่ค่า kernel ของ resize
  - ผลลัพธ์: max absolute difference = **5.96e-08** ทุกกรณี เท่ากับ float32 epsilon ยืนยันว่า edge tile ถูก zero-pad และสะสมเฉพาะพื้นที่จริง, weight ถูกหารถูกต้อง และ single-image fast path ย่อภาพกลับมาขนาดเดิมเหมือนกัน
- **ProductionParityTests::test_parity_holds_for_nonzero_and_large_overlap**
  - พฤติกรรมที่ผ่าน: ทดสอบ overlap = 0, 64 (ค่า production) และ 256 บนภาพ 700x900 ทุกค่าให้ max abs diff < 1e-6
  - หมายเหตุ: เดิมใส่ overlap=511 ซึ่งทำให้ stride = 1 และลูปวน 990,000 tile รอบทดสอบแรกจึงค้างเกิน 120 วินาที ถอดออกเพราะเป็นค่าที่ไร้ความหมาย (production จะช้าเหมือนกัน) ไม่ใช่พฤติกรรมที่ควรทดสอบ
- **TilingBehaviourTests (4 เคส)**
  - `test_constant_model_stays_constant_everywhere`: โมเดลที่คืนค่าคงที่ 0.7 ต้องได้ผลลัพธ์แบนทุกพิกเซลที่ 400x500, 640x480, 700x900, 2000x1368 — พิสูจน์ว่าไม่มี artifact จากการเฉลี่ยที่ขอบภาพ
  - `test_single_image_fast_path_returns_original_size`: ภาพ 300x700 (เล็กกว่า tile) ต้องคืน (300, 700) ไม่ใช่ (512, 512)
  - `test_non_binary_head_degrades_to_zeros`: head ที่มี 1 channel ต้องคืนค่า 0 ทั้งภาพแทนที่จะ crash
  - `test_output_is_probability_bounded`: ผลลัพธ์อยู่ในช่วง [0, 1]
- **MetricArithmeticTests (2 เคส)**
  - `test_confusion_and_dice_by_hand`: คำนวณด้วยมือจากตัวอย่าง pred=[1,1,0,0,1,0] gt=[1,0,1,0,0,0] ได้ tp=1, fp=2, fn=1, tn=2, Dice = 100*2/5, FPR = 100*2/4 ตรงกับ assertion
  - `test_empty_ground_truth_is_nan_and_total_miss_is_zero`: แหล่งที่ไม่มี forgery เลยต้องเป็น NaN ไม่ใช่ 0% (สำคัญเพราะ realtext มีภาพ label 0 ถึง 1,084 ภาพ) และกรณีพลาดหมดต้องได้ 0.0 ที่นิยามชัดเจน
- **HookWiringTests (11 เคส) — ส่วนที่สำคัญที่สุดของงานนี้**
  - `test_priority_precedes_runtime_info_hook`: ยืนยัน `priority == HIGHEST (0)` ซึ่งน้อยกว่า `RuntimeInfoHook` (VERY_HIGH = 10) นี่คือ guard กันการล้มเงียบ เพราะ RuntimeInfoHook คือตัว push metrics เข้า message hub ที่ LoggerHook ใช้ประกอบบรรทัด `Iter(val)` ถ้า hook นี้รันทีหลัง key ที่เพิ่มจะไม่ไปโผล่ใน log และ vis_data json โดยไม่มี error
  - `test_runs_on_interval_and_injects_keys`: เมื่อ `runner.iter % interval_iters == 0` ต้องเขียน `tiled_fake_forgery_dice` และ `tiled_fake_fpr` ลง metrics dict, คง `mIoU` เดิมไว้, และเขียน `tiled_val_log.jsonl` พร้อม `sampled_filenames` ในรอบแรก
  - `test_does_not_run_off_interval` / `test_does_not_run_at_iteration_zero`: นอกรอบต้องไม่แตะ metrics และไม่เขียนไฟล์ใด ๆ
  - `test_runs_on_final_iteration_even_off_interval`: ต้องรันเมื่อถึง `max_iters` แม้ไม่ตรงรอบ
  - `test_restores_training_mode`: ต้องคืนโหมด train ให้ loop หลัก
  - `test_sampled_filenames_logged_only_once`: รอบที่สองต้องไม่บันทึกรายชื่อซ้ำ
  - `test_rejects_bad_construction`: ต้อง raise สำหรับ sources ว่าง, interval ไม่บวก, source ไม่มี key, subsample เป็น 0 หรือชื่อไม่อยู่ใน sources (เพิ่ม validation นี้ใน `__init__` รอบนี้เพราะเดิมตรวจแบบ lazy ตอนสร้าง dataloader ซึ่งจะไม่ fail ตอน build config)
  - `test_missing_source_root_raises_instead_of_scoring_nothing`: path ที่ไม่มีต้อง raise `FileNotFoundError`
  - `test_per_source_seed_is_stable_across_processes`: รัน subprocess ด้วย `PYTHONHASHSEED=424242` แล้ว seed ต้องเหมือนกันทุกตัว — จุดนี้จับบั๊กจริงที่ผมเขียนเอง: เดิมใช้ `hash(name)` ซึ่ง Python สุ่ม salt ทุก process ทำให้ sample ไม่ reproducible เปลี่ยนเป็น `zlib.crc32`
  - `test_source_failure_does_not_kill_training_run`: เทสต์นี้เพิ่มจาก real-Runner smoke test เมื่อแหล่งหนึ่ง raise `OutOfMemoryError` ต้อง (1) ข้ามแหล่งนั้นและเขียน `{"error": ...}` ลง jsonl (2) แหล่งอื่นยังถูกให้คะแนนต่อ (3) ไม่เผยแพร่ key ของแหล่งที่ล้มเหลวเป็นตัวเลขครึ่งกลาง (4) `mIoU` เดิมไม่ถูกแตะ — เหตุผลคือฟีเจอร์ monitoring ต้องไม่มีสิทธิ์ทำลายรอบเทรนหลายชั่วโมง
- **ConfigV14Tests (13 เคส)**
  - `test_split_composition`: train = core 7, val = 9 (บวก aiforge/realtext), test = core 7
  - `test_new_domains_absent_from_training`: aiforge และ realtext ต้องไม่อยู่ใน train
  - `test_repeat_factors_cover_every_training_root`: ทุก root มี repeat factor และ imd2020 = 3
  - `test_budget_and_scheduler_end_together`: max_iters = PolyLR end = 250,000
  - `test_tiled_metrics_cannot_become_save_best_keys`: `tiled_*` ต้องไม่หลุดเข้า save_best
  - `test_everything_resolves_in_the_registry`: EncoderDecoder / AmpOptimWrapper / SourceAwareIoUMetric / BaseSegDataset / RepeatDataset resolve ได้ทั้งหมด
  - `test_workers_reduced_on_every_loader`: train/val/test = 4
  - `test_seed_matches_v11`: seed เท่ากัน
- **RealDataSmokeTests (4 เคส) — ทำงานกับข้อมูลจริงที่ mount อยู่**
  - `test_dataloader_subsamples_deterministically_and_keeps_native_size`: สุ่ม 12 ภาพจาก imd2020 val, สร้าง dataloaderสองครั้งต้องได้ลำดับไฟล์เดียวกัน, ไม่มีภาพซ้ำ, mask ต้องอยู่ที่ขนาดเดียวกับภาพ และต้องไม่ถูกย่อเป็น 512x512
  - `test_real_imd2020_sample_is_actually_larger_than_one_tile`: ยืนยัน premise ว่าภาพ imd2020 จริงมีขนาดใหญ่กว่า tile จริง (มิฉะนั้นเทสต์จะทดสอบแต่ fast path)
  - `test_tiled_probability_matches_native_shape_on_real_image`: ใช้ data preprocessor ตัวจริง, ผลลัพธ์ต้องมี shape เท่ากับ (H, W) ของภาพ
  - `test_hook_scores_real_image_end_to_end`: hook ทำงานครบเส้นทางกับ preprocessor จริงและภาพ native จริง, บันทึก `images: 3` และรายชื่อไฟล์ 3 รายการ — เทสต์นี้เป็น regression guard ของบั๊กด้านล่าง

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

**ไม่มีข้อผิดพลาด (0 Failed) ในผลรันสุดท้าย**

แต่รอบทดสอบก่อนหน้าพบ 2 บั๊กที่เป็นของจริง ไม่ใช่ของ test และแก้ไปแล้ว:

- **บั๊กที่ 1: ส่ง `SegDataSample` เข้า `img_metas` แทน metainfo dict**
  - สาเหตุ: `tiled_val._run_source` เรียก `tiled_forgery_probability(..., img_metas=[samples])` โดย `samples` เป็น `SegDataSample` แต่ mmseg ส่ง **metainfo dict** เข้า `slide_inference` (ดู `EncoderDecoder.predict` ที่ทำ `[d.metainfo for d in data_samples]`) ทำให้ `_patch_metas` พังที่ `meta['img_shape'] = ...` ด้วย `TypeError: '_StubSample' object does not support item assignment`
  - แก้: เพิ่ม `_as_meta()` ที่แปลง `SegDataSample` เป็น dict ก่อน
  - เหตุผลที่พบ: เทสต์แรกใช้ stub ที่คืน dict ทำให้บั๊กถูกบัง เทสต์ที่ใช้ข้อมูลจริงจึงจำเป็นต้องมี
- **บั๊กที่ 2: `data_preprocessor` คืน Tensor ไม่ใช่ list**
  - สาเหตุ: สาขา test ของ `SegDataPreProcessor` คืน `torch.stack(inputs, dim=0)` ซึ่งเป็น Tensor เมื่อนำมา iterate จะได้ slice ขนาด `(C, H, W)` ไม่ใช่ `(1, C, H, W)` ทำให้ `tiled_forgery_probability` อ่าน `image.shape[3]` แล้วได้ `IndexError: tuple index out of range`
  - แก้: แยก batch dimension ออกมา explicit ด้วย `stacked[i:i + 1]` และรองรับทั้ง Tensor และ list
  - เหตุผลที่พบ: stub preprocessor เดิมคืน list ทำให้บั๊กนี้ไม่โผล่จนกว่าจะใช้ preprocessor ตัวจริงใน `test_hook_scores_real_image_end_to_end`

### 3. Real-Runner smoke test (นอกเหนือจาก unit test)

รัน `tools/train.py` ด้วย config จริง v14 ย่อขนาดเล็ก (max_iters 2, val_interval 2, batch 1, val 2, ย่อแต่ละแหล่งเหลือ 2-6 ภาพ) และบังคับ hook ให้ยิงที่ iter 2 เพื่อปิดช่องว่างที่ unit test ด้วย stub runner มองไม่เห็น

- **สิ่งที่ผ่าน**: `Iter(val) [27/27]` จบครบ, training loop เดินครบ 2 iterations, hook เข้าทำงานจริงใน `after_val_epoch`, `TiledValidationHook` สร้าง dataloader ที่ `num_workers=2` หลัง CUDA init ได้โดย **ไม่ hang และไม่ crash** ซึ่งเป็นความกังวลหลักที่เคยมี (mp_start_method='fork' + fork หลัง CUDA init คือจุดที่ค้างบ่อย) และบรรทัด `Iter(val)` มี metric ครบทั้ง 28 คีย์จาก `SourceAwareIoUMetric`
- **สิ่งที่ไม่ผ่าน (เป็นข้อจำกัดของเครื่อง ไม่ใช่ของโค้ด)**: tiled pass OOM ทุกแหล่ง เพราะ VRAM ว่างจริงคือ 2.60 GiB (มี process อื่นถือ 1.04 GiB) เทียบที่ recipe นี้ต้องใช้ 6,299 MB
  - พฤติกรรมที่พบก่อนแก้: **รอบเทรนพัง** — `exit=1` พร้อม traceback จาก `tiled_val.py:411 after_val_epoch` ซึ่งแปลว่าฟีเจอร์ monitoring สามารถฆ่ารอบเทรนได้
  - พฤติกรรมหลังแก้: **`exit=0` — รอบเทรนจบปกติ** ทุกแหล่งถูกข้ามพร้อมข้อความ `TiledValidationHook skipped <source> at iter 2: OutOfMemoryError: ...` ที่ระดับ WARNING และบันทึก `{"error": "OutOfMemoryError: ..."}` ลง `tiled_val_log.jsonl` — ดังนั้นความล้มเหลวดังกล่าวจะไม่เงียบ แต่ไม่ทำลาย run
- ผลนี้เป็นหลักฐานว่า `priority='HIGHEST'` ทำงาน: hook ทำงานก่อน `RuntimeInfoHook` (รัน `after_val_epoch` ตามลำดับใน log) และการสร้าง dataloader ภายใน hook ไม่รบกวน lifecycle ของ Runner

### 4. การวัดที่ทำเพิ่มนอกเหนือจาก test

- **จำนวน forward pass จริง** ของ subsample ที่ตั้งใน config (นับด้วย counting model บนภาพจริง ทั้ง 3 แหล่ง):
  ```
  imd2020  1,500 images ->  9,258 forwards ( 6.2 tiles/image)
  aiforge     200 images ->  1,313 forwards ( 6.6 tiles/image)
  realtext    200 images ->  3,552 forwards (17.8 tiles/image)
  TOTAL     1,900 images -> 14,123 forwards
  ```
- **ประมาณเวลา**: ที่ 30.7 tiles/s (วัดจริงที่ batch 1 บน RTX 3050 4GB ของเครื่องนี้) = **7.7 นาทีต่อ trigger**, 10 triggers บน 250k iters ≈ 1.3 ชั่วโมง
- **ข้อจำกัดที่ต้องระบุ**: ตัวเลขความเร็ววัดบน GPU คนละเครื่องกับที่ใช้เทรนจริง (ดูหัวข้อข้อจำกัดด้านล่าง) จึงเป็นค่าประมาณระดับลำดับขนาด ไม่ใช่การวัดบนเครื่องเทรน และต้องวัดใหม่เมื่อรันจริงครั้งแรก

### 5. ข้อจำกัดและสิ่งที่ยังไม่ได้ทำ

- **ยังไม่ได้เทรน** เครื่องนี้เทรนไม่ได้: hostname `fedora`, RTX 3050 Laptop, VRAM 3.73 GiB แต่ training log ของ v1.0.6/v1.0.8 บันทึก peak memory 6,299 MB และเครื่องที่เทรนจริงคือ `linux-ac` ตาม `report/segformer-v1.0.8-test-2026-09-25.md` จึงยังไม่มีหลักฐานว่า v14 ดีกว่า v1.0.6
- **tiled pass ยังไม่เคยผ่านสักแหล่งเดียวในการรันจริง** เพราะ OOM บนเครื่องนี้ทุกแหล่ง — ยืนยันได้แค่ว่ากลไกทำงานและล้มเหลวอย่างปลอดภัย แต่ยังไม่ได้เห็นตัวเลข `tiled_*_forgery_dice` จริงแม้แต่ค่าเดียว
- **VRAM บนเครื่องเทรนยังไม่ได้วัด** tiled pass ทำงานทับ training peak + AdamW state; `tiled_val.py` เรียก `torch.cuda.empty_cache()` ก่อนเริ่มแล้ว แต่ต้องยืนยันบน linux-ac ว่าพอ ถ้าไม่พอ hook จะข้ามทุกแหล่งแบบเงียบๆ ไม่ใช่ error (โดยจะมี WARNING กำกับ)
- **ไม่ได้ยืนยันว่า linux-ac มี dataset ครบ 9 แหล่งด้วยการตรวจตรง** อนุมานจากหลักฐานว่า v1.0.7 และ v1.0.8 ผ่าน validation 70 รอบด้วย config ที่มี 9 แหล่ง และ metric จะ raise ถ้าแหล่งใดไม่ครบ
- **ค่า tiled ที่ hook จะได้ยังไม่มีตัวอย่างจริง** เทสต์ใช้ segmentor stub และน้ำหนักสุ่ม ไม่ใช่โมเดลที่เทรนแล้ว จึงพิสูจน์ได้แค่ว่ากลไกถูกต้อง ไม่ได้พิสูจน์คุณภาพ
- **ภาพในเทสต์เป็นข้อมูลจริงจาก `imd2020/images/val` เท่านั้น** ส่วน `test_parity_*` ใช้ภาพสุ่ม
- smoke config ที่ใช้ทดสอบอยู่ที่ `/tmp/v14_smoke/` ซึ่งอยู่นอก repo และไม่ถูกลบเพราะคำสั่ง `rm -rf` ถูกปฏิเสธ ผ่านการรัน จึงไม่กระทบโค้ดใน repo
- ไม่ได้แก้ `train.sh`, `test-model.sh`, `server/`, `admin-portal/` หรือ production model
