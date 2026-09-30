# Automated Test Report — Admin Export Cancellation Close-out

วันที่ทดสอบ: 2026-09-22
Branch baseline: `b9b30c88`

## 1. RED — Mid-export cancellation latency
คำสั่ง targeted pytest ของ `test_running_export_stops_within_batch_after_external_cancellation`

ผล: **FAIL**

หลักฐาน: worker เขียนภาพครบ **205** รายการ ขณะที่ test กำหนดว่าต้องหยุดภายใน batch ไม่เกิน 100 รายการ (`assert 205 <= 100` failed)

## 2. GREEN — Export lifecycle after periodic checkpoint
คำสั่ง: `pytest -q tests/utils/test_export_service_contracts.py`

ผล: **7/7 PASS**

ยืนยัน ZIP contract, external cancellation, periodic cancel checkpoint และ partial archive cleanup

## 3. RED — Finalization row-lock protocol
Worker test คาด `db.refresh(job, with_for_update=True)` แต่ actual call ไม่มี `with_for_update`

Cancel-route test compile PostgreSQL SQL แล้วไม่พบ `FOR UPDATE`
## 4. GREEN — Worker + cancel endpoint lock protocol
คำสั่ง targeted pytest ของ export/route contracts

ผล: **8 PASS / 0 FAIL**

ยืนยัน worker final refresh ใช้ row lock และ cancel endpoint compile เป็น `SELECT ... FOR UPDATE`

## 5. Full Server Regression
คำสั่ง: `PYTHONDONTWRITEBYTECODE=1 timeout 300s ./venv/bin/python -m pytest -p no:cacheprovider -q`

ผล: **132 passed / 3 skipped / 0 failed** ใน 12.68 s

Warnings 3 รายการเป็น dependency warnings เดิม:
- Surya Pydantic v2 class Config deprecation
- HuggingFace `resume_download` FutureWarning
- Starlette TestClient/httpx deprecation

## 6. Admin Backend Coverage Matrix
ผล targeted contracts: **74 passed / 0 failed**

Coverage:
- `app/api/v1/admin.py`: 95%
- `app/services/admin_access_policy.py`: 95%
- `app/services/admin_service.py`: 85%
- `app/services/export_service.py`: 89%
- รวม: **89%**
