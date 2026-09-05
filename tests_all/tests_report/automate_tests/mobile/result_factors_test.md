## 2026-09-04 09:51 +07 - Mobile Result & Factor Models Verification

- Target: scam_image_mobile/test/features/result/
- Command: `flutter test test/features/result/`
- Result: PASS
- Summary: Total: 31 | Passed: 31 | Failed: 0 | Skipped: 0 | Duration: 3s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **AnalysisResultModel.fromJson (Server Flat Format & Fallback)**:
  - พฤติกรรมที่ผ่าน: แปลงข้อมูลจาก Server Flat Format ที่มี `text_score`, `visual_score`, `source_score` เป็น `RiskFactorModel` ทั้ง 3 มิติได้อย่างถูกต้องครบถ้วน
- **RiskFactorModel Equality & Serialization**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบคุณสมบัติ Equatable และการแปลงเป็น JSON สำหรับการแสดงผลบน UI ของแต่ละปัจจัยความเสี่ยง
- **ResultBloc (Load Requested, Success, Error States)**:
  - พฤติกรรมที่ผ่าน: State Machine ของ ResultBloc ทำงานถูกต้อง สลับสถานะ Loading -> Loaded ตามข้อมูลผลการวิเคราะห์

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
