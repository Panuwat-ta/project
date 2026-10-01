## 2026-10-02 01:55 +07 - [Det-Head test-case รายเวอร์ชัน 26 เวอร์ชัน + กราฟรายเวอร์ชัน + ขึ้น Miro]

- Target: `model/segformer/Det-Head/eval_det_diagnostics.py` (รัน test-case 6 seed heads ที่ยังไม่มีผล), `model/segformer/Det-Head/plot_det_per_version.py` (ใหม่), `model/segformer/Det-Head/test_plot_det_per_version.py` (ใหม่ 6 เคส), Miro board `project:Scam Image Detection` (frame ใหม่ "6 Det-Head แยกแต่ละเวอร์ชัน")
- Command: `./venv/bin/python Det-Head/eval_det_diagnostics.py --head det5a_seed123=... (6 heads) --sets camera9,chatshot2,testcases --out-dir Det-Head/diagnostics_det_seeds_2026-10-02 --threshold 0.5 --batch-size 8 --device cuda`, `../venv/bin/python -m unittest test_plot_det_per_version -v`, `../venv/bin/python plot_det_per_version.py`
- Result: PASS
- Summary: Total: 38 | Passed: 38 | Failed: 0 | Skipped: 0
- (seed diagnostics 6 heads x 3 sets = 18 ชุดผล, unit test 6/6, packaging 26 เวอร์ชัน, Miro 1 frame + 26 images + 27 stickies ครบ)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Seed diagnostics — testcases 165 ภาพ (6/6 heads)**:
  - พฤติกรรมที่ผ่าน: 6 seed heads (det5a_seed123/seed7, det7a_seed123/seed7, det7b_seed123/seed7) ถูกสกัด feature จาก seg backbone `work_dirs/v1.0.6/best_mIoU_iter_195000.pth` ตัวเดียวกับรอบ 20 heads ในรอบเดียวบน GPU ได้ CSV 18 ไฟล์ + `diagnostics.json` ครบ ผลลัพธ์: det7b_seed123 ดีสุด accuracy 87.9% (spec 88.9 / rec 87.5), det7a_seed123 87.3%, det5a_seed7 ต่ำสุด 84.8% อยู่ในช่วงเดียวกับ 20 heads หลัก (80.6-88.5%) จึงรวมเปรียบเทียบกันได้
- **Seed diagnostics — camera9 9 ภาพ (6/6 heads)**:
  - พฤติกรรมที่ผ่าน: det7a_seed7 ได้ specificity 77.8% (7/9) ไม่ false alarm ดีสุดในกลุ่ม seed, det7b_seed123/seed7 ได้ 66.7%, det5a_seed7 ได้ 22.2% ต่ำสุด
- **Seed diagnostics — chatshot2 2 ภาพ (6/6 heads)**:
  - พฤติกรรมที่ผ่าน: det7a ทั้งสอง seed และ det7b_seed123 ได้ 2/2, det7b_seed7 ได้ 1/2, det5a ทั้งสอง seed ได้ 0/2; ตามเอกสารในหัวไฟล์สคริปต์ n=2 ใช้ดูแนวโน้มเท่านั้น ไม่ใช้ตัดสิน
- **Unit tests — `test_plot_det_per_version.py` (6/6)**:
  - พฤติกรรมที่ผ่าน: `test_two_runs_merge_without_overlap` ยืนยันว่ารวมผลสอง run dir โดยไม่ทับซ้อนได้และจำ source run ถูก, `test_duplicate_head_is_rejected` ยืนยันว่า head ซ้ำกันสอง run แล้ว raise `ValueError`, `test_empty_runs_are_rejected` ยืนยันว่า run ไม่มี head แล้ว raise, `test_main_heads_first_then_seeds_then_unknown` ยืนยันลำดับ 20 หลักก่อน seed แล้วค่อย head ไม่รู้จัก, `test_order_constant_covers_all_26_versions` ยืนยัน `HEAD_ORDER_ALL` มี 26 ตัว, `test_each_version_gets_csvs_summary_and_chart` ยืนยันว่าแต่ละเวอร์ชันได้ CSV 3 ไฟล์ + `summary.json` ตรงค่าจริง + กราฟ PNG ไม่ว่าง + `index.json` ครบ
- **Per-version packaging (26/26)**:
  - พฤติกรรมที่ผ่าน: `plot_det_per_version.py` อ่านเฉพาะผลที่เก็บไว้แล้วจากสอง run dir (ไม่รัน inference ใหม่) ได้โฟลเดอร์ `per_version_2026-10-02/<head>/` ครบ 26 เวอร์ชัน แต่ละโฟลเดอร์มี CSV 3 ไฟล์ (testcases 165 แถว, camera9 9 แถว, chatshot2 2 แถว ตรวจนับครบทุกเวอร์ชัน), `summary.json` (metrics + weight path + checkpoint + threshold) และ `<head>_scores.png` (ฮิสโตแกรมคะแนนแยกป้ายจริง + accuracy รายหมวด 8 หมวด) ขนาด 2085x1119 พร้อมรุ่นย่อ 1500x805 สำหรับ Miro
- **Miro upload (54/54 items)**:
  - พฤติกรรมที่ผ่าน: สร้าง frame "6 Det-Head แยกแต่ละเวอร์ชัน (26 charts: 20 หลัก + 6 seed)" ขนาด 5000x16000 ที่พิกัด (20390, 6720) ทางขวาของ frame 5 เดิม (สแกนพื้นที่ก่อนสร้างแล้วยืนยันว่าว่าง ไม่มี item เดิม 150 รายการอยู่ในบริเวณนั้น) แล้วอัปโหลดกราฟ 26 ภาพ + sticky สรุปตัวเลข 26 ใบ + sticky หัวข้อ 1 ใบ สแกนพื้นที่ซ้ำด้วย GET ได้ frame=1 image=26 sticky=27 ตรงตามที่สร้าง และ GET ราย item ยืนยัน frame/picture det7b อยู่ถูกพิกัดขนาดถูก (1500x805)

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- ไม่มีข้อผิดพลาด (0 Failed)

หมายเหตุข้อจำกัดที่พบระหว่างทำ (ไม่ใช่ failed test):
- Public Miro REST API ไม่รองรับ `position.relativeTo`/`parent` ทั้งตอนสร้างและ PATCH (ลองทั้ง multipart bracket-notation, JSON-string fields, JSON create และ PATCH แล้วได้ 400) จึงวางกราฟด้วยพิกัด canvas สัมบูรณ์ภายในขอบเขต frame แทนการเป็นลูกของ frame การย้าย frame ในภายหลังจะไม่พา item ไปด้วย ต่างจาก frame 5 เดิมที่ item เป็นลูก frame (สร้างด้วยวิธีอื่นก่อนหน้า)
- PATCH geometry ของรูปถูกเพิกเฉย (คงขนาดธรรมชาติของไฟล์) จึงย่อกราฟเหลือ 1500x805 ในเครื่องก่อนอัปโหลดด้วย PIL LANCZOS ไฟล์ต้นฉบับ 2085x1119 ยังอยู่ครบ
- ไม่ได้รัน set pilot11 เพราะไฟล์อยู่ใน `server/uploads` ไม่ใช่ `/home/panuwat/Pictures/Test-Cases` ตามที่ผู้ใช้สั่ง (เหมือนรอบ 20 heads)
