## 2026-09-03 04:34 +07 - Mobile XAI Dynamic Data Integration Test

- Target: `test/features/result`, `test/features/history`
- Command: `flutter test test/features/result test/features/history`
- Result: PASS
- Summary: Total: 67 | Passed: 67 | Failed: 0 | Skipped: 0 | Duration: 2s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **`AnalysisResultModel.fromJson` — Server Flat Format with XAI Explanation**:
  - พฤติกรรมที่ผ่าน: ส่ง JSON payload จาก API เซิร์ฟเวอร์ที่มีฟิลด์ `xai_explanation: "ภาพมีตำแหน่งที่ตรวจพบอยู่บริเวณ..."` ตัวโมเดลสามารถ parse และ map เข้าสู่ฟิลด์ `xaiExplanation` ของ Entity ได้ถูกต้อง 100% ไม่เป็น null และไม่ตกหล่น
- **`AnalysisResultModel.fromJson` — URL Normalization & Defaults**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการ resolve URL ภาพทั้งแบบ Relative Path (เชื่อมกับ API Base URL อัตโนมัติ), Absolute URL (คงค่าเดิม), และแปลง Backslash (`\`) เป็น Forward Slash (`/`) ผ่านเงื่อนไขทุกกรณี
- **`RiskFactorModel` — JSON Serialization & Deserialization**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการแปลง JSON ของ RiskFactor ครบทั้ง 3 ปัจจัย (Visual Anomaly, Text/OCR, Source Verification) ทั้งการแปลง String details และ Round-trip Serialization
- **`ResultBloc` — State Transitions**:
  - พฤติกรรมที่ผ่าน: เมื่อสั่ง `ResultLoadRequested` ตัว Bloc จะ emit `[ResultLoading, ResultLoaded]` ตามลำดับ และส่งต่อข้อมูลผลการวิเคราะห์ไปยัง UI อย่างถูกต้อง
- **`HistoryScreen` UI States**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการ Render หน้าจอประวัติทั้ง 4 สถานะหลัก (Empty State แสดง "ยังไม่มีประวัติการตรวจสอบ", Loading State แสดง ProgressBar, Loaded State แสดงรายการประวัติการสแกน, Error State แสดงข้อความแจ้งเตือน) ผ่านการตรวจสอบ Widget Finder ทั้งหมด

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed): ทุก Test Case ผ่านเกณฑ์ Assertion และ Type Contract ทั้งหมด

---

## 2026-09-03 04:38 +07 - Mobile Remove Hardcoded & Full Dynamic Data Test

- Target: `test/features/result`, `test/features/history`
- Command: `flutter test test/features/result test/features/history`
- Result: PASS
- Summary: Total: 67 | Passed: 67 | Failed: 0 | Skipped: 0 | Duration: 1s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **`AnalysisResultModel.fromJson` — Full Dynamic Fields Extraction**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการดึงข้อมูลจริงจาก Backend ครบ 4 ฟิลด์หลักที่เพิ่มเข้ามาใหม่ ได้แก่:
    - `aiGenProbability`: แปลงจาก `ai_gen_probability: 0.85` ใน JSON เป็น `double` ได้ถูกต้อง (ค่าที่ได้ 0.85 == 0.85)
    - `ocrText`: แปลงจาก `ocr_text: "ยอดเงิน 50,000 บาท โอนสำเร็จ"` ใน JSON เป็น `String` สมบูรณ์
    - `scamKeywords`: แปลงจาก `scam_keywords_found: ["ยอดเงิน", "โอนสำเร็จ"]` เป็น `List<String>` ได้ถูกต้องครบทุกคีย์
    - `xaiExplanation`: แปลงคำอธิบาย XAI จากโมเดลจริงสำเร็จ
- **`AnalysisResultModel.fromJson` — Risk Grade & Scale Mapping (3-Level Scale)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการคำนวณเกรดความเสี่ยงแบบ 3 ระดับ (Low 0-39, Medium 40-69, High 70-100) โดยไม่มีสถานะ Safe เก่าหลงเหลือ ค่าที่คำนวณได้ตรงตามตาราง Risk Level Helper
- **`HistoryDetailScreen` — Data Binding & Hardcoded Removal**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบว่าหน้าจอแสดงรายละเอียดประวัติแสดงผลข้อมูลจริงจาก Entity:
    - AI-Generated Probability แสดงผลจาก `result.aiGenProbability` จริง (ไม่ใช่ Mock 85%)
    - XAI Explanation แสดงผลจากคำอธิบาย AI จริง (ไม่ใช่ข้อความสแตติก "บริเวณมุมขวาบน...")
    - OCR Analysis สรุปผลจากคำสำคัญ `result.scamKeywords` และข้อความ `result.ocrText` จริง
- **`ResultBloc` & `HistoryBloc` — Stream Consistency**:
  - พฤติกรรมที่ผ่าน: BLoC จัดการข้อมูลชุดใหม่ที่เพิ่มฟิลด์ Dynamic Data ได้โดยไม่เกิด State Drop หรือ Deserialization Error

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed): ทุก Test Case ผ่านการทดสอบทั้งหมด ไม่พบค่า Null ที่ไม่ได้คาดหมาย หรือ Assertion Error ใดๆ
