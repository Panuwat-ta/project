# Model Full Debug Regression — 2026-09-20

## Verification
- `model/segformer/Test-Case/test_evaluation_core.py` ผ่าน project model environment: **3/3 passed**
- `model/segformer/tests_model/report/test_onnx_models.py` ผ่าน `server/venv`: **3/3 passed**

## Coverage
- binary metrics / absent forgery class
- production-style tiling + reassembly
- ONNX files/external weights existence
- input/output metadata contract
- dynamic inference finite/deterministic/normalized

## Environment note
การเรียกด้วย system Python 3.14 ครั้งแรก import NumPy ไม่ได้ (`ModuleNotFoundError`) แต่เมื่อใช้ project venv ตาม repo documentation tests ผ่านทั้งหมด จึงเป็น interpreter/environment mismatch ไม่ใช่ model-code defect
