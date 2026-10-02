## 2026-10-02 - Mobile development API runner และ quality gate tools

- Target: `scam_image_mobile/tool/tests/test_dev_runner.py`, `test_quality_gates.py`
- Command: `python3 -m unittest discover -s tool/tests -v`
- Result: PASS
- Summary: Total 18 | Passed 18 | Failed 0 | Skipped 0 | Duration 0.171s
- Additional config check: `python3 tool/run_dev.py --env-file /home/panuwat/project/scam_image_mobile/.env --check-config` ผ่าน โดยไม่แสดงหรือบันทึกค่า URL

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- `test_reads_only_api_base_url_and_ignores_other_values`: parser เลือกเฉพาะ API_BASE_URL; ค่า key อื่นใน fixture ไม่เข้าสู่ Flutter command
- `test_missing_or_duplicate_api_base_url_fails_closed` และ `test_missing_env_file_fails_closed`: ไม่มีไฟล์, ไม่มีค่า, ว่าง หรือกำหนดซ้ำถูกปฏิเสธ
- `test_invalid_url_shapes_are_rejected`: ปฏิเสธ scheme ที่ไม่ใช่ HTTP(S), userinfo, query, fragment และ path ที่ไม่ใช่ `/api/v1`
- `test_command_contains_only_explicit_development_configuration`: command กำหนด APP_ENV=development และ API_BASE_URL โดยคง args เช่น profile/device ไว้
- `test_config_file_and_release_overrides_are_rejected`: ปฏิเสธ `--dart-define-from-file`, การ override config และ `--release`
- `MainFunctionTests` 4 เคสครอบคลุม config check, launch args, invalid config และกรณีไม่พบ Flutter
- Quality gate tool tests เดิมอีก 8 เคสผ่าน ครอบคลุม branch coverage parser, fail-closed coverage gate และ dependency audit pagination/errors

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ใน final run 18/18. รอบแรกพบ 1 error จาก parser ที่ยังไม่รองรับ comment หลัง quoted URL; แก้ parser แล้วรันซ้ำผ่านครบ 18/18.
