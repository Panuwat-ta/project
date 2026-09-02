## 2026-09-02 04:55 +07

- Feature: ดูรายละเอียดประวัติแบบ local/offline
- Type: Lint
- Command: `/home/panuwat/develop/flutter/bin/cache/dart-sdk/bin/dart analyze`
- Result: Pass
- Notes: เพิ่มตาราง `scan_details` ใน `database_helper.dart:9` (migrate v1→v2), สร้าง `result_local_datasource.dart` (cache/get/clear + fallback จาก `scan_history`), แก้ `result_repository_impl.dart:13` ให้ลอง remote ก่อนแล้ว fallback ไป local เมื่อ `NetworkException`, wire ใน `injection_container.dart:19`, เปลี่ยน `Image.network` เป็น `CachedNetworkImage` ใน `history_detail_screen.dart:1` และ `analysis_result_screen.dart:1` เพื่อให้รูปโหลดจาก cache ตอนออฟไลน์, `dart analyze` 12 issues (warning/info เดิม ไม่มี error)

## 2026-09-02 04:56 +07

- Feature: ดูรายละเอียดประวัติแบบ local/offline
- Type: Manual Review
- Command: ตรวจสอบ `DatabaseHelper` version และ `git checkout HEAD --` กู้ไฟล์ที่ถูกลบ
- Result: Pass
- Notes: กู้ `database_helper.dart` และ `history_local_datasource.dart` ที่ถูกลบแบบ staged กลับมา, `git ls-files --deleted` = 0, ต้อง reinstall/clear data ครั้งหนึ่งให้ DB migrate เป็น v2 จึงจะดูออฟไลน์ได้
