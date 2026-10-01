# Det Head ONNX export + tile-size guard — 2026-09-30

- Target: `server/app/services/tiling.py`, `model/segformer/export_onnx_dynamic.py`, `model/segformer/Det-Head/det6_local.py`, `model/segformer/Det-Head/det5_local.py`
- Command: `cd server && ./venv/bin/python -m pytest tests -q`
- Result: PASS
- Summary: Total: 143 | Passed: 139 | Skipped: 4 | Failed: 0 | Duration: 6.52s

## 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **ชุดเต็ม `server/tests` (139 tests)**:
  - พฤติกรรมที่ผ่าน: pytest รันครบทุก test ใน `server/tests` และไม่มี failure หลังแก้ `tiling.py` (เพิ่ม `DET_EXPORT_TILE_SIZE` + guard ใน `det_score_image`) และ `export_onnx_dynamic.py` (เปลี่ยนจาก `load_det` เป็น `load_any_det`) โดย test ที่เกี่ยวกับ auth, session, admin, risk module, tiling และ ONNX worker ผ่านทั้งหมด ทำให้ยืนยันว่าการเพิ่ม guard ไม่ทำให้ regression ใด ๆ
  - เฉพาะเคสที่เกี่ยวกับการเปลี่ยนแปลง: `det_score_image` ยังคืนค่า `None` สำหรับโมเดล 1 output ตามเดิม และยังคืนค่า `None` เมื่อเกิด exception โดยไม่ raise ออกมา ทำให้พฤติกรรมเดิมที่ระบบคาดไว้ยังอยู่ครบ

## 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุ (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

## 3. การตรวจสอบเพิ่มเติมนอกเหนือจาก automated suite

รายการตรวจด้วยมือที่รันแยก ไม่ใช่ผลจาก pytest:

- `DET_EXPORT_TILE_SIZE` import ได้และมีค่า 512
- `det_score_image` กับโมเดล det7b (2 outputs): `tile_size=512` คืนค่า 0.00329, `tile_size=640` คืน `None`, `tile_size=1024` คืน `None` พร้อมข้อความบน stderr
- `det_score_image` กับโมเดล det2b (pooled, 2 outputs) ที่ `tile_size=512` คืนค่า 0.07467 ได้ตามปกติ คือ guard ไม่กระทบ head แบบ pooled
- โค้ดทั้ง 4 ไฟล์ผ่าน `ast.parse` และ `import` ได้จริง

## 4. ข้อจำกัดของการตรวจ

- ชุด test ของ server ไม่มี test ที่ครอบคลุมพฤติกรรมของ `det_score_image` กับ tile_size ที่ไม่ใช่ 512 ดังนั้นการทดสอบ guard ข้างต้นเป็นการรันด้วยมือ ไม่ใช่ regression test ที่จะทำให้ CI จับได้ ถ้าต้องการควรเพิ่ม test case ต่อ
- ผล ONNX parity ทุก resolution ไม่ได้รวมในรายงานนี้ เพราะเป็นการตรวจของฝั่ง model ด้วย `model/segformer/venv` ไม่ใช่ของ `server/venv`; ผลและหลักฐานอยู่ที่ `model/segformer/Det-Head/det_v1.0.6_det7b_webshot_camera/onnx_export_and_defect.json` และ `parity_multiresolution.json`
