# ScamGuard Test Suites & Execution Hub (`tests_all/`)

ไดเรกทอรี `tests_all/` เป็นศูนย์กลางการรวบรวมชุดกรณีทดสอบเชิงปฏิบัติการ (Executable Test Cases), ชุดทดสอบอัตโนมัติ (Automated Test Suites), Master Prompt สำหรับทดสอบระบบ และรายงานผลการรันการทดสอบจริง (Execution Reports) ของโครงการ ScamGuard

---

## โครงสร้างไดเรกทอรี (Directory Structure)

```text
tests_all/
├── README.md                        # เอกสารแนะนำภาพรวมและแนวทางการรันการทดสอบ (ไฟล์นี้)
├── promt.md                         # Master Prompt กำหนดบทบาท Senior Software Tester / QA Lead
├── rtm.md                           # ตารางสอบย้อนกลับความต้องการ (Requirements Traceability Matrix)
├── manual_tests/                    # ชุดกรณีทดสอบละเอียดสำหรับผู้ทดสอบปฏิบัติการจริง
│   ├── test_cases_mobile.md         # Test Cases ฝั่ง Mobile App (Flutter)
│   ├── test_cases_backend.md        # Test Cases ฝั่ง Backend API & Database (FastAPI)
│   ├── test_cases_ai_model.md       # Test Cases ฝั่ง AI Model, Tiling & Heatmap Pipeline
│   ├── test_cases_admin.md          # Test Cases ฝั่ง Admin Portal (React/Vite)
│   ├── test_cases_e2e.md            # Test Cases แบบ End-to-End ข้ามทั้งระบบ
│   └── test_cases_nfr.md            # Test Cases ด้าน Non-Functional (Security, Perf, WCAG)
├── automate_tests/                  # ชุดสคริปต์ทดสอบอัตโนมัติ (Automated Test Framework)
│   ├── Makefile                     # คำสั่งลัดสำหรับการรันชุดทดสอบ
│   ├── run.sh                       # สคริปต์รันการทดสอบอัตโนมัติ (API, E2E, Mobile, Perf)
│   ├── pytest.ini                   # การตั้งค่า Pytest และการออกรายงาน HTML/Coverage/JUnit
│   ├── requirements.txt             # ไลบรารี Python สำหรับชุดทดสอบ
│   ├── config/                      # การตั้งค่า Environments และ Settings
│   ├── fixtures/                    # ข้อมูล Mock, Payloads และ Image Factory
│   ├── helpers/                     # API Client, Auth Helper, Assertions
│   └── tests/                       # โค้ดทดสอบ Pytest (api, e2e, mobile bridge, locustfile)
└── tests_report/                    # บันทึกผลการรันการทดสอบอัตโนมัติจริง (Actual Test Execution Results)
    ├── automate_tests/              # รายงานผลการรันสคริปต์อัตโนมัติ (admin, mobile, model, server)
    └── manual_tests/                # รายงานผลการทดสอบด้วยตนเอง (Manual Execution Reports)
```

---

## ความสัมพันธ์กับเอกสารใน `Document/tests_doc/`

- **`Document/tests_doc/`**: จัดเก็บเอกสารระดับแผนงานและกลยุทธ์ เช่น `test_plan.md` (Master Test Plan & Strategy ตาม ISO/IEC/IEEE 29119) และแนวทางการออกแบบการทดสอบ
- **`tests_all/`**: จัดเก็บชุดทดสอบเชิงปฏิบัติการจริง สคริปต์อัตโนมัติ และผลลัพธ์การรันจริง

---

## คำสั่งการรันชุดทดสอบอัตโนมัติ (Automated Test Commands)

ชุดทดสอบอัตโนมัติสามารถรันได้โดยตรงผ่านสคริปต์ `run.sh` ภายใน `tests_all/automate_tests/`:

```bash
# 1. รันการทดสอบ Backend API ทั้งหมด
cd tests_all/automate_tests && ./run.sh api

# 2. รันการทดสอบ End-to-End Flow
cd tests_all/automate_tests && ./run.sh e2e

# 3. รันการทดสอบ Mobile Unit ผ่าน Bridge
cd tests_all/automate_tests && ./run.sh mobile

# 4. รันการทดสอบประสิทธิภาพ (Load & Performance Testing ด้วย Locust)
cd tests_all/automate_tests && ./run.sh perf

# 5. รันชุดทดสอบทั้งหมดพร้อมกัน
cd tests_all/automate_tests && ./run.sh all
```

---

## กฎเหล็กในการบันทึกผลการทดสอบ

1. **ห้ามใช้ Emoji เด็ดขาด** ในรายงานผลการทดสอบและเอกสารทุกฉบับ
2. การบันทึกผลการทดสอบอัตโนมัติลงใน `tests_all/tests_report/` ต้องเขียนแจกแจงเป็น**ภาษาไทย 4 มิติ**:
   - รายการที่ผ่าน (Passed Tests)
   - พฤติกรรมและเงื่อนไขที่ผ่าน (How it Passed)
   - รายการที่ไม่ผ่าน (Failed Tests)
   - สาเหตุและ Stack Trace ที่ไม่ผ่าน (How & Why it Failed)
