## 2026-09-02 05:20 +07

- Feature: แสดงความเสี่ยงเป็น % และปรับเกณฑ์เหลือ 3 ระดับ
- Type: Lint + Unit
- Command: `/home/panuwat/develop/flutter/bin/cache/dart-sdk/bin/dart analyze` และ `flutter test test/core/utils/risk_level_helper_test.dart test/features/result/data/models/analysis_result_model_test.dart`
- Result: Pass
- Notes: เปลี่ยน `RiskLevel` จาก 4 เป็น 3 ระดับ (`low 0-39`, `medium 40-69`, `high 70-100`), หน้าหลักแสดง `%` รวม (`history_screen.dart:374` badge `'$score%'`), รายละเอียดแยก `%` ต่อส่วน (`_buildScorePill` `'$score%'`), `dart analyze` 12 issues ไม่มี error, 44 tests ผ่าน
