# Server Full Debug Regression — 2026-09-20

## Scope
ตรวจ backend หลัง refactor scan pipeline / ONNX runner / tiling และแก้ defects ที่พบจาก code review ต่อเนื่อง

## Defects fixed
- `onnx_worker.py` import `tiling` แบบ top-level ทำ package import พัง -> ใช้ package-safe import
- `onnx_runner.py` malformed/empty stdout เคยโยน JSONDecodeError -> คืน structured failure (`stdout_json=None`)
- callers ใน inference/admin dry-run ตรวจ JSON result ก่อนใช้งาน
- parity test เดิม bypass worker wrapper -> เปลี่ยนให้เรียก wrapper จริง
- เพิ่ม orchestration tests สำหรับ scan cache hit/miss
- `admin_service.global_search()` ใช้ `Scan.risk_score/risk_level` ที่ไม่มีจริง -> ใช้ canonical fields + `grade_for`
- root tests เก่า import `SessionLocal`, `async_session_maker`, `analyze_image` ที่ถูกลบ -> rewrite เป็น pytest ของ `create_scan_task`
- `tests/db/test_db.py` เดิมเป็น script ไม่มี pytest test -> เปลี่ยนเป็น integration test `SELECT 1`

## Verification
- `server/venv/bin/python -m pytest server/tests --ignore=server/tests/inference --ignore=server/tests/api/test_scan_xai_live.py -q`
  - **53 passed, 1 skipped, 2 dependency warnings**
- targeted regression suite: **18 passed**
- `server/tests/utils`: **25 passed**
- deterministic API suite: **25 passed, 1 skipped**
- root `server/tests/test_*.py`: **2 passed**
- DB integration: **1 passed**
- `python -m compileall -q server/app server/tests`: **PASS**
- `git diff --cached --check` / `git diff --check`: **PASS**

## Runtime health
- PostgreSQL: reachable, `SELECT 1` passed
- Redis container had been gracefully stopped (`Exited (0)`, SIGTERM in logs), not crashed
- Started `scamguard_redis`; `redis-cli PING` -> `PONG`
- `/health` after recovery -> `status=ok`, `database=ok`, `redis=ok`
- Redis warns `vm.overcommit_memory = 0`; this is an OS operational risk, not an application-code failure

## Exclusions / limitations
- `server/tests/inference/*` and `server/tests/api/test_scan_xai_live.py` were intentionally excluded from the deterministic broad suite because they depend on live model/GPU/runtime resources.
- Dependency warnings remain from Surya/Pydantic v2 deprecation and Hugging Face `resume_download`; no application test failed because of them.
