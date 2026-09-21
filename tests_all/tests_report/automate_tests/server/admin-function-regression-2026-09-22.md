# Automated Server Admin Function Regression — 2026-09-22

## Test Target
Server full regression พร้อม coverage เฉพาะ Admin route/access/service/export surface หลัง function-level fixes

## Command
`PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider -q --cov=app.api.v1.admin --cov=app.services.admin_access_policy --cov=app.services.admin_service --cov=app.services.export_service --cov-report=term-missing`

## Result
- **131 passed**
- **3 skipped**
- **0 failed**
- **3 dependency warnings**
- Runtime: **14.29 s**

## Coverage
- `app/api/v1/admin.py`: **95%**
- `app/services/admin_access_policy.py`: **95%**
- `app/services/admin_service.py`: **85%**
- `app/services/export_service.py`: **89%**
- Combined Admin surface: **89%**

Regression coverage includes malformed refresh subject, user detail monthly statistics, model row locking, audit reason, Redis health, export ZIP/cancel/failure lifecycle และ nested upload media URL / missing optional heatmap contracts
