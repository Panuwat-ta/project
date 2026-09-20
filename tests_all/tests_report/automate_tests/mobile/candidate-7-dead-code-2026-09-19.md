## 2026-09-19 06:40 +07 - [Candidate 7: dead usecases + shim unification]

- Target: scam_image_mobile (ลบ usecase layer) + model/tests_model (รวม shim)
- Command: `flutter analyze`, `flutter test`, `test_qualitative_onnx.py v1.0.0` (model venv), `bash -n` ทั้งสอง .sh
- Result: PASS (มี 2 fail ของเดิม)
- Summary: ลบ 24 ไฟล์ (usecase 17 + shim 7) | flutter 238 passed 2 failed (ของเดิม) | analyze 12 issues ไม่มี error ใหม่

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[ลบ usecase 17 ไฟล์]**:
  - พฤติกรรมที่ผ่าน: verify ครบ 18 ชื่อ (รวม integration_test) ไม่มี caller นอกไฟล์ตัวเองแม้แต่ test เดียว ลบแล้ว analyze ไม่มี error ใหม่ flutter test เท่าเดิม (238-2 ทั้งก่อน/หลัง — พิสูจน์ด้วย stash)
- **[รวม shim 7 → 1]**:
  - พฤติกรรมที่ผ่าน: `test_qualitative_onnx.py <version>` รัน v1.0.0 จริงได้ outputs เดิม (.png/.svg), argv ผิดได้ usage, `bash -n` + embedded python parse ผ่านทั้ง .sh และ add-v-mode.sh (เลิก generate ไฟล์รายเวอร์ชัน แต่ยังเขียน manifest เหมือนเดิม)
- **[Track B]**:
  - พฤติกรรมที่ผ่าน: คง defer (det_score ยังไม่มี consumer) — ไม่แตะตาม stop condition

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- **[scan_bloc_test 2 เคส]**: ของเดิมบน clean tree ไม่เกี่ยวกับงานนี้
- หมายเหตุ: ตอน grill พูด 18 ไฟล์ นับจริง 17 (auth5/history3/report1/result1/scan3/settings4) — แก้ตัวเลขให้ตรงหลักฐาน
