# SegFormer Test System Audit Report

วันที่ตรวจ: 23 กันยายน 2569

## ขอบเขตที่ตรวจ

- `/home/panuwat/project/model/segformer/configs`
- `/home/panuwat/project/model/segformer/work_dirs`
- `/home/panuwat/project/model/segformer/tests_model`
- `/home/panuwat/project/model/segformer/Test-Case`
- `/home/panuwat/Pictures/Test-Cases`

เป้าหมายคือยืนยันว่าการเปรียบเทียบโมเดลใช้ Test-Case มาตรฐานเดียวกัน ตรวจความถูกต้องของผล v1.0.0-v1.0.7 และหาปัญหาใน test/report automation โดยไม่ได้แก้โค้ดหรือผลการทดสอบในรอบนี้

## Executive summary

พบว่า dataset Test-Case มาตรฐานมีโครงสร้างถูกต้อง: quantitative 105 image/mask pairs ครบ 7 หมวด และ qualitative 30 original/manipulated pairs ครบทั้งหมด ผล unit/inventory tests 6/6 ผ่าน และ ONNX contract tests 3/3 ผ่านสำหรับโมเดลใน manifest ปัจจุบัน

อย่างไรก็ตามพบปัญหาสำคัญ 7 รายการ โดย 3 รายการกระทบความน่าเชื่อถือของ workflow/report โดยตรง และอีก 2 รายการเป็น model-regression ของ v1.0.7 ที่ทำให้ยังไม่ควร promote แทน v1.0.6 ตาม gate ที่กำหนดไว้

สถานะโดยรวม: **ตัว dataset และ ONNX package ใช้งานได้ แต่ reporting/release-gate automation ยังไม่สอดคล้องกับสถานะล่าสุดของโปรเจกต์ และ v1.0.7 ยังไม่ผ่าน promotion criteria ครบ**

## สิ่งที่ตรวจแล้วว่าใช้งานได้ถูกต้อง

1. `Test-Case/test_source_inventory.py` ยืนยัน masked dataset = 105 cases และมี 7 categories ตรงตามมาตรฐาน
2. ทุก image/mask pair มีขนาดตรงกัน และ mask เป็น binary `{0,1}`
3. qualitative dataset มีครบ 30 คู่ ตั้งแต่ `pair001` ถึง `pair030`
4. `test_evaluation_core.py` ตรวจสูตร confusion/metric และ tiled inference ผ่าน
5. ผลรวม unit + inventory tests: **6 tests passed**
6. `tests_model/report/test_onnx_models.py` ตรวจ ONNX ทุกเวอร์ชันใน `evaluation_manifest.json` ผ่านครบ 3 contract tests
7. ONNX model และ external `.onnx.data` มีอยู่จริง และ dynamic input/output contract ผ่าน
8. Locked common test ของ v1.0.0-v1.0.7 ใช้ dataset id `scamguard-locked-multisource-test-v1` และจบครบ 2,504 batches
9. Local quantitative Test-Case ใช้แหล่งเดียวกันทุกโมเดล: `/home/panuwat/Pictures/Test-Cases/with_mask`
10. Local qualitative Test-Case ใช้แหล่งเดียวกันทุกโมเดล: `/home/panuwat/Pictures/Test-Cases/pairs`

ดังนั้นปัญหาหลักที่พบไม่ใช่ไฟล์ Test-Case หายหรือ mask เสีย แต่เป็นเรื่อง model regression, stale gate/documentation และ generated output ที่สามารถอยู่ในสถานะไม่สอดคล้องกันได้

## Finding 1 — HIGH: v1.0.7 ยังไม่ผ่าน promotion gate ที่กำหนดใน config v12

Promotion criteria ที่ระบุไว้คือ locked mDice >= 97.29, local IMD2020 Forgery Dice > 50% และ overall FPR <= 1.0%

ผลจริง v1.0.7: locked mDice 97.36% = ผ่าน, IMD2020 Forgery Dice 49.62% = ไม่ผ่าน, overall FPR 1.08% = ไม่ผ่าน

**ผลกระทบ:** หาก promote v1.0.7 เป็น production โดยดูเฉพาะ locked common test จะข้าม gate 2 จาก 3 ข้อที่ config ตั้งไว้เอง

**ข้อเสนอ:** คง v1.0.6 เป็น production baseline จนกว่า v1.0.7 หรือรุ่นถัดไปจะผ่านทุก gate หรือมีการทบทวน gate อย่างเป็นทางการพร้อมเหตุผลและหลักฐาน

## Finding 2 — HIGH: v1.0.7 regression บน Test-Case มาตรฐาน 105 รูป

เมื่อใช้รูปมาตรฐานชุดเดียวกันและ inference pipeline เดียวกัน v1.0.7 แย่กว่า v1.0.6 โดยรวม:

| Metric | v1.0.6 | v1.0.7 | Delta |
|---|---:|---:|---:|
| mIoU | 83.14 | 81.13 | -2.02 |
| mDice | 90.17 | 88.78 | -1.39 |
| Forgery IoU | 69.35 | 65.76 | -3.60 |
| Forgery Dice | 81.90 | 79.34 | -2.56 |
| Accuracy | 97.13 | 96.72 | -0.42 |
| FPR | 0.83 | 1.08 | +0.25 |

รายหมวด v1.0.7 ดีขึ้นใน CopyMove (+8.76 Forgery Dice), IMD2020 (+7.49), Inpainting (+3.23) และ Splicing (+0.60) แต่ถอยใน CASIA (-11.35) และ Face (-2.33)

**ผลกระทบ:** v1.0.7 แก้ weakness บาง domain ได้จริง แต่เกิด trade-off จน overall local regression set ถอย และ false positive สูงขึ้น

**ข้อเสนอ:** ก่อนสร้าง v1.0.8 ให้ทำ ablation ของ CopyPasteForgery/repeat factors โดยเฉพาะ CASIA 5->4, IMD2020 2->3 และการใช้ CopyPasteForgery กับ forged sources ทุกชุด เพื่อหาสาเหตุ regression

## Finding 3 — HIGH: selective qualitative run เขียนทับ combined output

สถานะปัจจุบัน `Test-Case/output/qualitative/summary.json` มี `versions: ["v1.0.7"]` และ `qualitative_pair_scores.csv` มีเพียง 30 rows ของ v1.0.7 แต่ใน `output/qualitative/` ยังมีโฟลเดอร์ผล v1.0.0-v1.0.7 อยู่ครบ

ในทางกลับกัน quantitative summary ยังมีครบ 8 versions และ `overall.csv` มี 8 rows

**ผลกระทบ:** report consumer ที่อ่าน combined qualitative CSV/summary อาจเข้าใจผิดว่ามีผลเพียง v1.0.7 หรือได้จำนวน version ไม่ตรงกับ artefact ที่อยู่ใน disk

**สาเหตุ:** `render_qualitative_pairs.py` เขียน `qualitative_pair_scores.csv` และ `summary.json` ใหม่จากเฉพาะ versions ที่เลือกในรอบนั้น จึง overwrite combined result เดิม

**ข้อเสนอ:** แยก output เป็น 2 ระดับ: per-run/per-version ที่เขียนทับได้ และ canonical combined report ที่ regenerate จาก per-version CSV ทั้งหมด หรือ merge โดย version key อย่าง deterministic

## Finding 4 — MEDIUM: release gate ยัง hard-code ที่ v1.0.5

`Test-Case/run_test_cases.sh` ตรวจว่ารอบที่เลือกมี `v1.0.5` หรือไม่ และ default evaluator ใช้ `--release-version v1.0.5`

ขณะนี้ v1.0.6 และ v1.0.7 มีผลใหม่กว่า แต่ full run ยังสามารถ fail เพราะ legacy v1.0.5 mDice = 84.87% ต่ำกว่า gate 85% แม้ candidate ใหม่จะเป็นคนละรุ่น

**ผลกระทบ:** CI/runner status ไม่สื่อสถานะ release candidate ปัจจุบัน และอาจเกิด false failure หรือในทางกลับกัน selective run ของรุ่นใหม่จะใช้ `--no-release-gate` จนไม่ enforce promotion criteria ของรุ่นนั้น

**ข้อเสนอ:** ย้าย release policy ออกจาก shell hard-code ไปไว้ใน manifest หรือ release-policy JSON/YAML เช่น `release_candidate`, `minimum_mdice`, `maximum_fpr`, per-category gates แล้วให้ runner อ่านจาก source of truth เดียว

## Finding 5 — MEDIUM: เอกสาร `tests_model/README.md` ล้าสมัย

README ยังระบุว่า Common Test ชุดเดียวกันใช้สำหรับ `v1.0.0–v1.0.5` แต่ `evaluation_manifest.json` มี v1.0.6 และ v1.0.7 พร้อม locked test 2,504 batches แล้ว

README ยังระบุว่าแต่ละ `tests_model/v/<version>/` มี `test_qualitative_onnx.py` แต่ตรวจ filesystem แล้วไม่พบไฟล์นี้ใน v1.0.0-v1.0.7 ปัจจุบัน การรันจริงใช้ central `tests_model/test_qualitative_onnx.py` ผ่าน `test_qualitative_onnx.sh`

**ผลกระทบ:** คนทำงานตาม README อาจหาไฟล์ที่ไม่มีอยู่หรือเข้าใจ scope ของ common test ผิด

**ข้อเสนอ:** อัปเดต README ให้ดึงรายการ versions จาก manifest และแก้ส่วน per-version entry point ให้ตรง implementation ปัจจุบัน

## Finding 6 — MEDIUM: `RESULTS.md` อ้าง path ที่ไม่มีอยู่จริง

`Test-Case/RESULTS.md` ระบุว่าสำเนาสำหรับคนอ่านอยู่ใน `spreadsheets/quantitative/` และ `spreadsheets/qualitative/` แต่ตรวจ filesystem ปัจจุบันแล้วไม่มี `/home/panuwat/project/model/segformer/Test-Case/spreadsheets`

**ผลกระทบ:** เอกสารส่งต่อหรือ audit trail ชี้ไปที่ artefact ที่ไม่มีอยู่ ทำให้ reproduce/report review สับสน

**ข้อเสนอ:** ถ้าเลิกใช้ spreadsheets ให้ลบข้อความออกจาก RESULTS.md; ถ้ายังต้องใช้ ให้สร้าง export step ใน runner และเพิ่ม test ตรวจว่า referenced artefacts มีจริง

## Finding 7 — LOW/MEDIUM: canonical report state ไม่มี atomic consistency

ผลใน `Test-Case/output/` มาจากหลายรอบการรันต่างเวลา จึงเป็นไปได้ที่ quantitative เป็น combined 8 versions แต่ qualitative เป็น selective 1 version โดยไม่มี run manifest กลางบอกว่าไฟล์ชุดใดถูกสร้างพร้อมกัน

**ผลกระทบ:** เมื่อนำ output ไปสร้างรายงานต่อ อาจผสม artefact คนละ run โดยไม่รู้ตัว

**ข้อเสนอ:** ทุก run ควรมี `run_id`, timestamp, selected versions, dataset fingerprint/hash, manifest hash, command/options และ output file list แล้ว publish canonical report หลังทุก stage สำเร็จเท่านั้น

## หมายเหตุเกี่ยวกับ threshold

Quantitative ใช้ forgery threshold 50% ส่วน qualitative display ใช้ 40% ปัจจุบันโค้ดระบุชัดว่า qualitative เป็น manual review และไม่มี accuracy claim จึงยังไม่ถือว่าเป็น metric bug แต่ควรเขียน threshold บนรูปและรายงานทุกครั้งเพื่อป้องกันการเอาค่าทั้งสองประเภทมาเทียบกันผิด

## ลำดับความสำคัญในการแก้

1. **P1:** ห้าม promote v1.0.7 เป็น production จนกว่าจะตัดสิน promotion gate ใหม่หรือผ่านครบตามเกณฑ์เดิม
2. **P1:** แก้ selective-run overwrite ของ qualitative combined output
3. **P1:** เปลี่ยน release gate จาก hard-coded v1.0.5 เป็น policy ที่ผูกกับ release candidate ปัจจุบัน
4. **P2:** เพิ่ม run manifest/fingerprint เพื่อให้ quantitative และ qualitative มี provenance เดียวกัน
5. **P2:** อัปเดต `tests_model/README.md` และ `Test-Case/RESULTS.md` ให้ตรง filesystem/manifest ปัจจุบัน
6. **P2:** ทำ ablation v12 เพื่อรักษา gain ของ CopyMove/IMD2020/Inpainting แต่ลด regression ใน CASIA และ FPR

## สรุปสถานะโมเดล

Locked common test: v1.0.7 สูงกว่า v1.0.6 เล็กน้อย (mIoU 94.96 vs 94.83, mDice 97.36 vs 97.29)

Standard local Test-Case 105 รูป: v1.0.6 ยังดีกว่าโดยรวม (mIoU 83.14 vs 81.13, Forgery Dice 81.90 vs 79.34, FPR 0.83 vs 1.08)

ดังนั้นผลทั้งสองชุดไม่ได้ขัดกัน แต่สะท้อนคนละ distribution: v1.0.7 เพิ่มความสามารถในบาง manipulation domain แต่มี regression ที่ CASIA/Face และ false positive สูงขึ้น จึงยังไม่ผ่านเกณฑ์ promotion ที่ v12 กำหนดเอง

## Final assessment

- Dataset Test-Case มาตรฐาน: **PASS**
- Image/mask integrity: **PASS**
- Unit/inventory tests: **PASS 6/6**
- ONNX contract tests: **PASS 3/3**
- Locked test completeness: **PASS**
- v1.0.7 promotion gate: **FAIL 2/3 criteria**
- Generated report consistency: **FAIL — qualitative combined artefacts ถูก selective run overwrite**
- Documentation consistency: **NEEDS UPDATE**

รายงานนี้เป็น audit-only; ยังไม่ได้แก้ source code, test output, deployment config หรือ model checkpoint ใด ๆ
