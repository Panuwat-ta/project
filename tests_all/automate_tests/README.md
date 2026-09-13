# ScamGuard — Automate Test Suite

> ศูนย์รวม Automate Test สำหรับโปรเจค ScamGuard ทั้งหมด (Backend / Mobile / E2E / Performance)

**Path:** `/home/panuwat/project/tests_all/automate_tests/` (โฟลเดอร์จริงที่มี `Makefile` / `run.sh` / `pytest.ini`)

---

## โครงสร้างโฟลเดอร์

```
tests_all/automate_tests/
├── config/               # ตั้งค่า environment, base URL, credentials
│   ├── settings.py       # โหลด config จาก env + yaml
│   └── environments.yaml # dev / staging / prod
├── tests/
│   ├── api/              # Backend API automate (FastAPI) — pytest + httpx
│   ├── mobile/           # Mobile automate — bridge ไป flutter test + integration_test
│   ├── e2e/              # End-to-End ข้ามระบบ (API + DB + Mobile flow)
│   └── performance/      # Load test (locust)
├── helpers/              # ตัวช่วยใช้ร่วมกัน (api_client, auth, assertions)
├── fixtures/
│   ├── images/           # รูปทดสอบ (ว่าง — ไม่มี symlink, ไม่มี server/tests/test_img)
│   ├── payloads/         # JSON payload ตัวอย่าง
│   └── reports/          # template รายงาน
├── reports/              # ผลรัน — html / junit / coverage
├── scripts/              # สคริปต์ช่วยรัน
├── pytest.ini            # config pytest
├── requirements.txt
├── Makefile              # make test-api, test-all
└── run.sh                # one-click runner
```

---

## วิธีรัน (Quick Start)

```bash
# 1. ติดตั้ง deps (แยก venv ของ automate_tests)
cd /home/panuwat/project/tests_all/automate_tests
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. ตั้งค่า env (copy จากตัวอย่าง)
cp .env.example .env
# แก้ BASE_URL, ADMIN credentials ถ้าต้องการ

# 3. รันทั้งหมด
./run.sh all              # = api + e2e + mobile (ถ้ามี flutter)
./run.sh api              # เฉพาะ API
./run.sh e2e              # เฉพาะ E2E
./run.sh mobile           # สั่ง flutter test ผ่าน bridge
./run.sh perf --users 50  # load test

# หรือใช้ Makefile
make test-api
make test-all
make report   # เปิด html report

# หรือ pytest โดยตรง
pytest tests/api -v --html=reports/html/api.html
pytest tests/e2e -v
```

---

## เชื่อมกับของเดิม

- **Server tests เดิม** ยังอยู่ที่ `server/tests/` — `tests_all/automate_tests/tests/api/` import app จาก `server/app` โดยตรงและรันซ้ำได้
- **Mobile tests เดิม** อยู่ที่ `scam_image_mobile/test` — `tests/mobile/` จะเป็น bridge เรียก `flutter test` อัตโนมัติ ไม่ต้องย้ายไฟล์เดิม
- ชุดภาพมาตรฐาน `fixtures/images/` (สเปก+ที่มา — ยังไม่มีไฟล์จริง ห้ามอ้างว่ามี):
  1. `std-clean-01.jpg` — ภาพปกติ 1920×1080 JPG ~3MB (ถ่ายเอง/ลิขสิทธิ์ทีม) — negative control
  2. `std-splice-01.png` — ภาพตัดต่อทดสอบ 1920×1080 PNG (สร้างจากชุด CASIA 2.0 ตามลิขสิทธิ์งานวิจัย) — positive control
  3. `std-oversize-01.jpg` — ภาพเกินลิมิต >10MB (ขยายจาก std-clean-01) — ทดสอบ boundary FR-INPUT-04
  4. `std-invalid-01.txt` — ไฟล์นามสกุลไม่รองรับ — ทดสอบ Magic Bytes/validation
  - เกณฑ์: ทุกภาพต้องมี SHA-256 บันทึกใน `fixtures/images/SHA256SUMS` (สร้างพร้อมไฟล์จริง); สคริปต์ที่ต้องใช้ภาพแต่ไฟล์ยังไม่มี ให้ skip พร้อมเหตุผล ห้ามแต่งผล

---

## CI (GitHub Actions)

ระบบได้ตั้งค่า GitHub Actions Workflow ไว้ที่ `.github/workflows/automate_test.yml` เพื่อรันอัตโนมัติเมื่อมีการ Push หรือสร้าง Pull Request ไปยัง branch `main` หรือ `develop`:

- **Job Name / Check Name**: `automate_test` (ตรงกับที่ตั้งไว้ใน GitHub Ruleset)
- **Services**: มี PostgreSQL 15 และ Redis 7 รันเป็น CI Services พร้อม Auto Migration
- **Artifacts**: อัปโหลดรายงานการทดสอบ HTML และ JUnit XML อัตโนมัติ (`reports/html/`, `reports/junit.xml`)

## Smoke suite ฝั่ง Admin/Model + Quality gate (สเปกเอกสาร — ยังไม่มี suite จริง)

- Admin smoke (ต้องมีก่อน sign-off รอบถัดไป, owner QA Lead): login admin → เปิด dashboard → อนุมัติ/ปัดตก 1 รายงาน → ตรวจ audit log — ผ่าน 100% จึงปล่อยได้
- Model smoke (owner AI Owner): สกัด OCR 1 ภาพ + คำนวณ risk 1 เคส + ตรวจ threshold ≥85% ตาม `server/tests/tests_model/README.md` — ผ่าน 100% จึงปล่อยได้
- Quality gate ฝั่ง CI: API suite + E2E smoke + Admin/Model smoke ต้อง PASS 100% (P0/P1) และไม่มี Critical/Major ค้าง จึง merge/PR ผ่าน — สถานะปัจจุบัน: ยังไม่มี gate นี้ใน workflow (GAP เอกสาร; ไม่แก้ workflow ในงานนี้)

---

## กลยุทธ์การทดสอบอัตโนมัติ (Strategy)

- เกณฑ์เลือกเคสเข้า automate: รันซ้ำบ่อย (smoke/regression ทุกรอบ) / oracle ตรวจด้วยเครื่องได้ (API status/schema, คำนวณคะแนน) / ไม่ต้องใช้ตา (คง UI subjective เป็น manual)
- เป้าหมาย coverage: API critical paths 100% (auth/scan/history/report/admin), regression suite ผ่าน 100% ก่อนปล่อย
- นโยบาย flaky: quarantine แยกไฟล์ + เปิด Bug P2 + ต้องนิ่ง 3 รอบติดจึงกลับเข้า suite หลัก
- Owner: API suite — Backend Owner; E2E — QA Lead; Mobile bridge — Mobile Owner; Perf — Backend Owner

## เพิ่ม Test Case ใหม่

1. API: เพิ่มไฟล์ `tests/api/test_*.py` ใช้ `helpers.api_client` และ `helpers.auth_helper`
2. E2E: เพิ่มใน `tests/e2e/test_*.py` ใช้ flow เต็ม `register -> login -> scan -> history -> report`
3. Mobile: เพิ่มใน `scam_image_mobile/test` ตามปกติ แล้วรันผ่าน `make test-mobile` จะถูกรวมรายงานด้วย

---

## รายงานและการดีบัก

- `reports/html/` — pytest-html
- `reports/junit.xml` — สำหรับ CI
- `reports/coverage/` — coverage html
- ดู log แบบ verbose: `pytest -s -vv`

---

## GAP ที่ทราบ (Known Gaps)

- `tests_all/tests_report/automate_tests/admin/` และ `.../model/` ยังไม่มีรายงานผลรัน (มีแค่ `.gitkeep`) — ต้องรันสคริปต์จริงของ Admin Portal / Model pipeline ก่อนจึงบันทึกเป็นรายงาน 4 มิติภาษาไทย ห้ามบันทึก review ด้วยสายตา
- เกณฑ์เวลากลางของโครงการ (unify ทุกเอกสาร): Cache Hit P95 ≤ 3s (E2E), Full Inference P50 ≤ 15s / P95 ≤ 25s / P99 ≤ 35s (ภาพ 1920x1080 JPG 3MB) — สคริปต์ perf (`tests/performance/locustfile.py`) ต้อง tag request แยกกลุ่ม `cache_hit` / `cache_miss` แล้วรายงาน percentile แยกกลุ่ม (P50/P95/P99 ต่อกลุ่ม) ทุกรอบ — สถานะปัจจุบัน: GAP (ยังไม่แยกกลุ่ม ดู `test_cases_nfr.md` TC-NFR-PERF-05) ห้ามกรอกตัวเลขที่ไม่ได้มาจากรันจริง (เงื่อนไขเอกสารเท่านั้น ไม่แก้โค้ดในงานนี้)

