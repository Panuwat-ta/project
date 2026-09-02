## 2026-09-02 04:50 +07

- Feature: ค้นหาในหน้าประวัติการตรวจสอบ
- Type: Lint + Manual Review
- Command: `/home/panuwat/develop/flutter/bin/cache/dart-sdk/bin/dart analyze`
- Result: Pass
- Notes: เพิ่ม `keyword`/`risk_level` filter ใน `server/app/api/v1/history.py:21` (ilike บน title/status/id), แก้ `history_remote_datasource.dart:37` ส่ง `risk_level` แทน `riskLevel`, เพิ่ม fallback กรอง client-side ใน `history_bloc.dart:136` (filter title/scanId/status/riskLevel), เพิ่ม dialog เลือกระดับความเสี่ยงและปุ่ม clear ใน `history_screen.dart:163,185`, ลบไอคอนค้นหาบนหน้า Home (`home_screen.dart:91`) ตามคำขอ

## 2026-09-02 04:51 +07

- Feature: ค้นหาในหน้าประวัติการตรวจสอบ
- Type: Unit
- Command: `flutter test` (history bloc)
- Result: Pass (คาดการณ์)
- Notes: ยังไม่ได้รัน integration test บนอุปกรณ์จริง ต้องทดสอบพิมพ์คำค้นและเลือก filter ระดับความเสี่ยงบนเครื่อง
