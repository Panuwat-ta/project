# ScamGuard — Automate Test Suite

> ศูนย์รวม Automate Test สำหรับโปรเจค ScamGuard ทั้งหมด (Backend / Mobile / E2E / Performance)

**Path:** `/home/panuwat/project/automate_test`  
**Alias:** `/home/panuwat/project/automate test` (symlink ไปที่เดียวกัน รองรับชื่อมีเว้นวรรค)

---

## โครงสร้างโฟลเดอร์

```
automate_test/
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
│   ├── images/           # รูปทดสอบ (symlink จาก server/tests/test_img)
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
# 1. ติดตั้ง deps (แยก venv ของ automate_test)
cd /home/panuwat/project/automate_test
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

- **Server tests เดิม** ยังอยู่ที่ `server/tests/` — automate_test จะ import app จาก `server/app` โดยตรงและรันซ้ำได้
- **Mobile tests เดิม** อยู่ที่ `scam_image_mobile/test` — `tests/mobile/` จะเป็น bridge เรียก `flutter test` อัตโนมัติ ไม่ต้องย้ายไฟล์เดิม
- รูปทดสอบใช้ร่วมกันผ่าน symlink `fixtures/images -> ../../server/tests/test_img`

---

## CI

เติมใน GitHub Actions ได้ทันที:

```yaml
- run: cd automate_test && pip install -r requirements.txt && ./run.sh api --junit
```

รายงาน JUnit อยู่ที่ `reports/junit.xml` และ HTML ที่ `reports/html/`

---

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

