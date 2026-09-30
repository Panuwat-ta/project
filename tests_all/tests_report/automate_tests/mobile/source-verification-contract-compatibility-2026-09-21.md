# รายงาน Mobile Compatibility — Source Verification Contract — 2026-09-21

## 1. ขอบเขต
- ตรวจ compatibility ของ Flutter result parser หลัง Backend เปลี่ยน unavailable source เป็น `source_score=null`
- ไม่แก้ production Dart เพราะ `AnalysisResultModel.fromJson()` มี guard `source_score != null` อยู่แล้ว

## 2. Functional Verification
- Command: `flutter test test/features/result/data/models/analysis_result_model_test.dart test/features/result/data/datasources/result_remote_datasource_test.dart`
- ผล: 19 passed, 0 failed
- Canonical scan response ยัง parse ได้ และ null source score ไม่สร้าง RiskFactor ประเภท source

## 3. Regression / Contract Compatibility
- Risk grade parsing เดิมยังแยก low/medium/high/unknown ตาม contract
- URL parsing, empty response rejection และ Dio 404 mapping ผ่านเหมือนเดิม
- การมี field ใหม่ `source_status` ไม่ทำให้ parser แตก เพราะ JSON field ที่ไม่ได้ใช้ถูกละเว้น

## 4. ข้อจำกัด
- Mobile entity ปัจจุบันยังไม่ได้เก็บ `source_status` เป็น field โดยตรง; unavailable UI อาศัยการไม่มี source factor ตาม behavior redesign ปัจจุบัน
- รอบนี้ไม่เปลี่ยน UI/mobile domain model เพราะไม่มี regression ที่ยืนยันได้ และต้องการจำกัด scope ของ contract change
