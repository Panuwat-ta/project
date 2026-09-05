# ScamGuard Test Documentation Catalog

เอกสารในไดเรกทอรี `Document/tests_doc/` รวบรวมแผนแม่บท กลยุทธ์ และแนวทางการประกันคุณภาพซอฟต์แวร์ (Software Quality Assurance & Testing Plans) ของระบบ ScamGuard ตามมาตรฐานสากล ISO/IEC/IEEE 29119

---

## โครงสร้างเอกสาร (Documentation Structure)

```text
Document/tests_doc/
├── README.md                            # สารบัญและภาพรวมเอกสารการทดสอบทั้งหมด (ไฟล์นี้)
└── test_plan/                           # โฟลเดอร์แผนแม่บทและกลยุทธ์การทดสอบ (Master Test Plan & Strategies)
    ├── README.md                        # แผนแม่บทการทดสอบระบบ (Master Test Plan & Strategy ตาม ISO/IEC/IEEE 29119)
    ├── manual_tests_doc/                # เอกสารแผนและแนวทางการทดสอบแบบ Manual รายโมดูล
    │   ├── test_plan_mobile.md          # แผนการทดสอบ Mobile App (Flutter)
    │   ├── test_plan_backend.md         # แผนการทดสอบ Backend API & Database (FastAPI)
    │   ├── test_plan_ai_model.md        # แผนการทดสอบ AI Model & Heatmap Pipeline
    │   ├── test_plan_admin.md           # แผนการทดสอบ Admin Portal (React/Vite)
    │   └── test_plan_nfr.md             # แผนการทดสอบ Non-Functional (Security, Perf, WCAG)
    └── automate_tests_doc/              # เอกสารแผนและสถาปัตยกรรมชุดทดสอบอัตโนมัติ
        ├── test_plan_api_automation.md  # แผนการทดสอบ Backend API Automation (Pytest)
        ├── test_plan_e2e_automation.md  # แผนการทดสอบ End-to-End Automation
        └── test_plan_performance.md     # แผนการทดสอบ Load & Performance Testing (Locust)
```

---

## ความเชื่อมโยงกับไดเรกทอรี `tests_all/`

- **`Document/tests_doc/`**: จัดเก็บเอกสารแผนงาน นโยบาย เกณฑ์การตรวจรับ และการออกแบบการทดสอบ (Strategic & Design Documents)
- **`tests_all/manual_tests/`**: จัดเก็บชุดกรณีทดสอบละเอียดสำหรับผู้ทดสอบลงมือปฏิบัติจริง (Executable Test Cases)
- **`tests_all/automate_tests/`**: จัดเก็บซอร์สโค้ดของสคริปต์ทดสอบอัตโนมัติจริง (Automated Test Suites)
- **`tests_all/tests_report/`**: จัดเก็บรายงานบันทึกผลการรันการทดสอบอัตโนมัติจริง (Execution Reports)
- **`tests_all/promt.md`**: Master Prompt สำหรับสั่งการ AI Agent หรือมอบหมายงาน QA Engineer
