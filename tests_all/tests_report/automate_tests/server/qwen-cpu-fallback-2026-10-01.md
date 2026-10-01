## 2026-10-01 20:00 +07 - Qwen บน CPU เมื่อ GPU ไม่พอ + สถานะ "กำลังสร้าง" และ poll รับข้อความทีหลัง

- Target: `server/app/services/inference_service.py`, `scam_image_mobile` (bloc, screen, localization), `server/tests`
- Command: `./venv/bin/python -m pytest tests -q` | `flutter test` | `flutter build apk --debug`
- Result: PASS
- Summary: server 176 passed / 3 skipped; mobile 417 passed / 0 failed; APK build สำเร็จ

### บริบท

เดิมเมื่อ GPU ไม่พอ โค้ดตั้ง `xai_model = None` ทำให้ข้อความ XAI มาจาก template สำเร็จรูปเสมอ ทั้งที่ไฟล์ Qwen2.5-1.5B (1.1 GB) มีอยู่ ผู้ใช้สั่งว่าในกรณี GPU ไม่พอให้รัน Qwen บน CPU พร้อมบอกผู้ใช้ว่าข้อความกำลังสร้าง แล้วส่งมาทีหลังเมื่อเสร็จ

### 1. สิ่งที่เปลี่ยน

**Server** (`app/services/inference_service.py`):
- สาขา `should_defer_xai_gpu` เดิมปิดโมเดลทิ้ง เปลี่ยนเป็นลองโหลดด้วย `n_gpu_layers=0` (CPU) ถ้าล้มเหลวจริงๆ จึงค่อยเป็น None → template (พฤติกรรมเดิมเป็นทางสุดท้าย)
- ไม่แตะ `.env` (`XAI_GPU_LAYERS` ยังเป็น -1) ตาม constraint ที่ห้ามแก้ไฟล์ env
- flow Phase 1/2 เดิมรองรับอยู่แล้ว: Phase 1 บันทึก `xai_explanation=None`, status `processing_text`, progress 90 → client เห็นผลก่อน; Phase 2 เติมข้อความแล้วเป็น `completed`/100 (timeout 300s)

**Mobile**:
- `result_bloc.dart`: เพิ่ม event `ResultPollRequested` โพลทุก 5 วินาที สูงสุด 60 ครั้ง (~5 นาที ตรงกับ XAI_TIMEOUT) เฉพาะเมื่อ `isXaiPending` (summary ว่าง + status ไม่ใช่ completed/failed) โพลไม่สั่ง loading ซ้ำเพื่อไม่ให้จอกระพริบ โพลล้มครั้งเดียวหยุดเงียบๆ โดยไม่ทิ้งผลเดิม
- `analysis_result_screen.dart`: ถ้า summary ว่างและกำลังประมวลผล แสดง spinner + ข้อความ `result_summary_generating`; ถ้าเสร็จแล้วยังว่าง แสดง `result_summary_unavailable` เหมือนเดิม
- localization เพิ่ม `result_summary_generating` ไทย/อังกฤษ: "กำลังสร้างคำอธิบายจาก AI กรุณารอสักครู่ ระบบจะแสดงข้อความเมื่อสร้างเสร็จ"

### 2. ผลทดสอบจริง

- **โหลด CPU**: `Llama(n_gpu_layers=0)` สำเร็จใน 0.7 วินาที RAM เครื่องมี available ~4 GB ไฟล์โมเดล 1.1 GB ผ่านสบาย
- **สแกนจริง end-to-end** (ภาพกล้อง to169): visual=0, risk=0, status completed ข้อความที่ได้คือ "ตรวจพบความผิดปกติระดับต่ำบริเวณส่วนบนของภาพ ไม่พบร่องรอยการตัดต่อหรือการดัดแปลงที่ชัดเจน..." — สำนวนธรรมชาติจาก LLM ไม่ใช่ template (template จะขึ้นต้นว่า "ผลการวิเคราะห์ภาพอยู่ในระดับต่ำ (0/100)")
- **server tests**: 176 passed / 3 skipped / 0 failed
- **mobile tests**: 417 passed / 0 failed (เพิ่ม test `isXaiPending` 4 เงื่อนไข + poll ไม่สั่ง loading ซ้ำ)
- **บนมือถือ RMX3370**: ติดตั้ง APK ใหม่สำเร็จ เปิดแอป FATAL 0 ครั้ง

### 3. รายการที่ไม่ผ่าน (Failed Tests)

ไม่มีข้อผิดพลาด (0 Failed)

### 4. หมายเหตุ

- ข้อความที่ Qwen สร้างมีประโยค "ภาพถูกส่งเสริมโดย AI อยู่ในเกณฑ์ต่ำ" ซึ่งสำนวนแปลกเล็กน้อย มาจาก few-shot example ใน prompt ที่ยังมีคำว่า "โอกาส AI" ถ้าต้องการสำนวนเนี้ยบกว่านี้ต้องแก้ prompt (งานเนื้อความ แยกทำได้)
- ข้อมูลทดสอบ (user + scans + ไฟล์) ลบออกจาก DB แล้ว คงสถานะว่างไว้ตามเดิม
- Server restart แล้ว (โหลด Qwen CPU สำเร็จ ยืนยันจาก log) Qwen ค้างใน RAM ตลอดเวลาที่ server รัน