# รายงาน Runtime Inference Hardening — 2026-09-21

## ขอบเขต
ตรวจและแก้ runtime crash/timeout ของ scan pipeline บนเครื่องทดสอบ NVIDIA GPU VRAM 4 GiB รวมถึง live scan test harness ที่ใช้ตรวจ pipeline จริงผ่าน API

## ปัญหาที่พบจากหลักฐานจริง
- Live test อ้าง `server/tests/test.png` ซึ่งไม่มีอยู่จริง; เปลี่ยนมาใช้ `server/tests/test1.png` ที่อยู่ใน repository
- Live test hardcode user id `6` ซึ่งไม่มีใน DB ปัจจุบัน; เปลี่ยนเป็นเลือก active user จาก DB แบบ read-only
- Poll deadline เดิม 30 วินาทีสั้นกว่างบ timeout ของ pipeline จริง และ polling GET สามารถ timeout ชั่วคราวเมื่อ inference ใช้ทรัพยากรหนัก
- XAI timeout เดิมใช้ worker thread ที่ไม่ยอมคืน control เมื่อ host task ถูก cancel
- OCR timeout เดิมอยู่ใน `ThreadPoolExecutor` context manager ซึ่งจะ `shutdown(wait=True)` ตอนออกจาก `with` ทำให้ timeout แล้วก็ยังรอ worker ต่อ
- Coredump PID 863064 ยืนยัน `SIGABRT` ใน `libggml-cuda` ระหว่าง `llama_decode`; Python ไม่สามารถ catch native abort นี้ได้

## การแก้ไข
- เพิ่ม XAI worker timeout ที่คืน deterministic fallback เมื่อหมดเวลา
- แก้ OCR executor ให้ไม่ wait worker ที่ยังค้างหลัง timeout
- เพิ่ม GPU preflight: เมื่อ GPU มี total VRAM ต่ำกว่า 4097 MiB หรือ free VRAM ต่ำกว่า 1500 MiB จะไม่โหลด Qwen GPU XAI และใช้ deterministic fallback
- ปรับ live test ให้ใช้ fixture/user/deadline ตาม runtime contract และทน transient polling timeout
## ผลทดสอบ
- Targeted hardening tests: PASS
- Live scan pipeline หลัง hardening: `1 passed` ในประมาณ 6 วินาที
- Full server suite รอบสุดท้าย: `66 passed, 3 skipped, 0 failed, 3 warnings` ใน 11.96 วินาที
- Startup log ของ test process ยืนยัน `Deferring GPU XAI model to deterministic fallback (VRAM total=4096 MiB, free=2731 MiB)`
- Server health ตอบ HTTP 200; health payload เป็น `degraded` เพราะ Redis local ไม่ได้รัน (`database=ok`, `redis=error`)

## Cleanup
- Final test suite สร้าง `Live GPU Verification Test` 1 แถว
- ลบ test row สำเร็จ 1 แถว เหลือ 0
- ลบ generated files ที่ไม่มี scan อื่นอ้างอิง 2 ไฟล์
- ไม่ลบไฟล์ที่มี reference อื่น

## Warning / ข้อจำกัด
- Dependency warnings เดิม: Surya Pydantic deprecation, Hugging Face `resume_download`, FastAPI TestClient/Starlette deprecation
- system coredump เก่าจาก native CUDA crashes ยังอยู่ใน OS และไม่ได้ลบอัตโนมัติ
- XAI บน 4 GiB ใช้ deterministic fallback เพื่อรักษา availability; ไม่อ้างว่า Qwen GPU inference สำเร็จบน hardware นี้
- `loop-context --check` ไม่มีใน environment และ fallback command timed out; attempts ถูกบันทึกใน loop ledger ตามจริง
