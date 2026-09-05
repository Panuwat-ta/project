## 2026-09-05 07:42 +07 - Mobile Models API_BASE_URL Strict .env Verification

- Target: `scam_image_mobile/test/features/result/data/models/analysis_result_model_test.dart`, `scam_image_mobile/test/features/history/data/models/scan_history_item_model_test.dart`
- Command: `flutter test test/features/result/data/models/analysis_result_model_test.dart test/features/history/data/models/scan_history_item_model_test.dart`
- Result: PASS
- Summary: Total: 30 | Passed: 30 | Failed: 0 | Skipped: 0 | Duration: 1s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **AnalysisResultModel URL parsing**:
  - พฤติกรรมที่ผ่าน: การแปลง URL สัมพัทธ์และรูปภาพหลักฐาน/Heatmap อ้างอิงจากตัวแปร `API_BASE_URL` ใน `dotenv` อย่างถูกต้อง เมื่อกำหนดค่าผ่าน `dotenv.loadFromString` ระบบสามารถต่อพาธและแปลงกลับเป็น URL สมบูรณ์ได้ครบถ้วน
- **AnalysisResultModel.fromJson**:
  - พฤติกรรมที่ผ่าน: แปลงโครงสร้างข้อมูลคะแนนความเสี่ยง ระดับความเสี่ยง และปัจจัยความเสี่ยงจาก JSON เป็นโมเดล Dart ได้ถูกต้องครบทุกคีย์
- **ScanHistoryItemModel URL parsing**:
  - พฤติกรรมที่ผ่าน: การต่อ Base URL ของรูปภาพ Thumbnail จากประวัติการสแกนผ่าน `API_BASE_URL` ที่ได้จาก `dotenv` สำเร็จ และรักษา URL แบบ Absolute ไว้อย่างถูกต้อง
- **ScanHistoryItemModel.fromJson**:
  - พฤติกรรมที่ผ่าน: แปลงข้อมูลจากทั้ง snake_case และ camelCase พร้อมกำหนดสถานะเริ่มต้นได้อย่างถูกต้อง

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
