## 2026-09-19 04:20 +07 - [ONNX Spawn Adapter / test_onnx_runner.py]

- Target: server/tests/utils/test_onnx_runner.py (ใหม่)
- Command: `source venv/bin/activate && python -m pytest tests/utils/test_onnx_runner.py tests/utils/test_scan_seams.py tests/utils/test_risk_module.py tests/utils/test_risk_calculator.py tests/api/test_scan.py -q` (workdir: `server/`)
- Result: PASS
- Summary: Total: 23 | Passed: 22 | Failed: 0 | Skipped: 1 | Duration: ~0.4 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[test_build_worker_env_carries_model_and_tiling (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: env มี MODEL_PATH/TILE/OVERLAP ตรง settings และล้าง CUDA_VISIBLE_DEVICES ว่าง — ครบทั้งสอง callers เดิม
- **[test_run_parses_last_line_and_records_env (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: parse JSON บรรทัดสุดท้ายทิ้ง print กวน, spawn ด้วย worker_path + env ถูกต้อง
- **[test_run_sends_b64_stdin (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: stdin ที่ส่งคือ base64 ของ bytes ต้นฉบับ
- **[test_timeout_kills_and_reports (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: TimeoutExpired แล้ว kill + communicate ซ้ำ + timed_out True + stdout_json None — เท่า fallback เดิม
- **[test_failure_surfaces_stderr (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: returncode != 0 คืน stderr_text ครบ
- **[18 เคสเดิม (risk/scan seams/test_scan)]**:
  - พฤติกรรมที่ผ่าน: ผ่านครบ ยืนยันว่า 2 callers ผ่าน adapter แล้ว behavior ไม่เปลี่ยน

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed; 1 skipped ของเดิม; ระหว่างทางแก้บั๊กใน test เอง 2 จุด: factory ทิ้ง spawn args + positional ตกผิด param — ไม่ใช่บั๊กโค้ด)
