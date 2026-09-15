---
title: "กรณีทดสอบและรูปแบบตาราง Manual Test (Test Cases)"
category: testing
tags: [testing, manual-tests, test-cases, ieee-829, istqb, traceability, spreadsheets]
sources: [.agents/AGENTS.md, tests_all/README.md, tests_all/manual_tests/test_cases_admin.md, tests_all/manual_tests/test_cases_ai_model.md, tests_all/manual_tests/test_cases_backend.md, tests_all/manual_tests/test_cases_mobile.md, tests_all/manual_tests/test_cases_nfr.md, tests_all/manual_tests/test_cases_image_testset.md, tests_all/manual_tests/test_cases_e2e.md, tests_all/tests_report/README.md]
updated: 2026-09-15
---

# กรณีทดสอบและรูปแบบตาราง Manual Test (Test Cases)

ศูนย์กลางกรณีทดสอบแบบ manual ของโปรเจค ScamGuard อยู่ที่ `tests_all/manual_tests/` โดยใช้ตารางมาตรฐาน 10 คอลัมน์ตาม IEEE 829 / ISTQB และมีสำเนา CSV สำหรับสเปรดชีตแยกตามแต่ละพื้นที่

---

## 1. รูปแบบตาราง 10 คอลัมน์ (IEEE 829 / ISTQB)

กรณีทดสอบแบบ manual ใน `tests_all/manual_tests/` ทุกไฟล์ต้องใช้ตาราง Markdown ที่มี 10 คอลัมน์ตามลำดับนี้พอดี (อ้างอิง `.agents/AGENTS.md` ส่วนที่ 9):

`Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority`

กฎของแต่ละคอลัมน์:

- **Test Case ID** — รูปแบบ `TC-<area>-<NN>` (เช่น `TC-IMGM-01`, `TC-BE-AUTH-01`)
- **Requirement ID** — ต้องอ้างอิง FR/NFR ที่มีอยู่จริง (เช่น `FR-SYS-05`) เพื่อการสืบย้อนกลับ ห้ามแต่งขึ้นเอง
- **Preconditions** — เป็นคอลัมน์แยกต่างหาก (สภาพแวดล้อม/สถานะก่อนทดสอบ) ห้ามฝังไว้ใน Description
- **Test Data** — ต้องอ้างอิง path ของไฟล์หรือ ID ที่มีอยู่จริง ห้ามใช้ค่าที่แต่งขึ้น
- **Actual Result / Status** — กรอกตอนรันจริง (`Pass` / `Fail` + พฤติกรรมที่พบ) ก่อนรันให้ใส่ `To Do`
- **Priority** — หนึ่งใน: High / Medium / Low (ในไฟล์ปัจจุบันบางพื้นที่ใช้ระดับ `P0 (Blocker)` / `P1 (High)` / `P2 (Medium)`)
- ต้องมีเคสล้มเหลว/เคสลบ (negative cases: input ไม่ถูกต้อง, คู่ข้อมูลไม่ตรงกัน, ไฟล์หาย) ควบคู่กับเคสสำเร็จ

> [!NOTE]
> ไฟล์ e2e (`test_cases_e2e.md`) เป็นข้อยกเว้นเชิงโครงสร้าง: ส่วน scenario ข้ามระบบใช้ตาราง `Scenario ID | Journey Name | Source System | Intermediate Systems | Target System | Priority` และมีตาราง traceability ย่อย (`กลุ่ม | TC ย่อย | Requirement ID`) แยกต่างหาก ไม่ใช่ตาราง 10 คอลัมน์

---

## 2. กฎ md-canonical + CSV ใน spreadsheets/<area>/

ไฟล์ Markdown ใน `tests_all/manual_tests/` คือต้นฉบับหลัก (canonical) ส่วนสำเนา CSV ของตารางอยู่ใน `spreadsheets/<area>/` สำหรับเปิดในสเปรดชีต:

- **กฎ:** md เป็น canonical — ทุกครั้งที่แก้ md ต้องสร้าง CSV ใหม่ให้ตรงกันเสมอ
- ผังไฟล์ต่อพื้นที่ (จำนวนแถว CSV ไม่นับแถว header ตรงกับจำนวนเคสใน md):

| พื้นที่ | ไฟล์ md (canonical) | ไฟล์ CSV | จำนวนเคส |
| :--- | :--- | :--- | :--- |
| admin | `tests_all/manual_tests/test_cases_admin.md` | `spreadsheets/admin/test_cases_admin.csv` | 25 |
| ai_model | `tests_all/manual_tests/test_cases_ai_model.md` | `spreadsheets/ai_model/test_cases_ai_model.csv` | 24 |
| backend | `tests_all/manual_tests/test_cases_backend.md` | `spreadsheets/backend/test_cases_backend.csv` | 32 |
| mobile | `tests_all/manual_tests/test_cases_mobile.md` | `spreadsheets/mobile/test_cases_mobile.csv` | 43 |
| nfr | `tests_all/manual_tests/test_cases_nfr.md` | `spreadsheets/nfr/test_cases_nfr.csv` | 23 |
| image_testset | `tests_all/manual_tests/test_cases_image_testset.md` | `spreadsheets/image_testset/test_cases_image_testset.csv` | 6 |
| e2e | `tests_all/manual_tests/test_cases_e2e.md` | `spreadsheets/e2e/test_cases_e2e_scenarios.csv` + `spreadsheets/e2e/test_cases_e2e_traceability.csv` | 10 scenarios + 4 กลุ่ม traceability |

- โฟลเดอร์ `spreadsheets/qualitative/` และ `spreadsheets/quantitative/` ไม่ใช่กรณีทดสอบแบบ manual แต่เป็นสำเนาสำหรับคนอ่านของผลประเมินโมเดล SegFormer (ต้นฉบับจริงอยู่ที่ `model/segformer/Test-Case/output/`) หลังรันสคริปต์ประเมินใหม่ต้องคัดลอกมาที่ `spreadsheets/` อีกครั้งเพราะสคริปต์ไม่ได้เขียนลงที่นั่นโดยตรง

---

## 3. จำนวนเคสต่อไฟล์ (นับจากไฟล์จริง)

ยอดรวมนับจากแถวตารางในไฟล์ md (`grep -c "^| TC-"`) และยืนยันด้วยจำนวนแถว CSV:

- **admin — 25 เคส** (`TC-ADM-*`): หมวด Admin Authentication, Dashboard, การจัดการผู้ใช้/โมเดล และการตรวจสอบ
- **ai_model — 24 เคส** (`TC-AI-*`): หมวด Overlapping Tiling Inference, SegFormer/ONNX, Surya OCR, Qwen2.5 XAI และ Source Verification
- **backend — 32 เคส** (`TC-BE-*`): หมวด Authentication & RBAC, Scan API, ฐานข้อมูล PostgreSQL/Redis และ endpoint ฝั่งเซิร์ฟเวอร์
- **mobile — 43 เคส** (`TC-MOB-*`): หมวด Authentication, หน้าจอสแกน/ผลลัพธ์, ประวัติ และการซิงก์กับ backend จริง
- **nfr — 23 เคส** (`TC-NFR-*`): หมวด Performance & Reliability, Security, PDPA และ Accessibility
- **image_testset — 6 เคส** (`TC-IMGM-*` / `TC-IMGP-*`): เคส mask (ภาพปลอมที่มี ground-truth mask, ภาพจริง mask ดำล้วน, face morphing) และเคสคู่เทียบ (pairs) อ้างอิงข้อมูลจริงที่ `/home/panuwat/Pictures/Test-Cases/`
- **e2e — 10 scenarios + 4 กลุ่ม traceability**: scenario ข้ามระบบ (`TC-E2E-SCAN-01` ถึง `TC-E2E-HIST-10`) ครอบคลุม journey สแกนเต็มรูปแบบ, cache hit, รายงาน incident, deploy โมเดล, ban ผู้ใช้, offline sync, วงจร register-to-audit, token refresh, regression หลัง deploy และการลบประวัติ ส่วนตาราง traceability แยกย่อย scenario หลักเป็น 4 กลุ่ม (A: อัปโหลด+ตรวจไฟล์, B: ประมวลผล AI, C: แสดงผลลัพธ์, D: บันทึกประวัติ+เวลา)

---

## 4. ที่เก็บผลการรันทดสอบ (`tests_all/tests_report/`)

ไดเรกทอรี `tests_all/tests_report/` สงวนไว้สำหรับ**ผลการรันทดสอบอัตโนมัติจริงเท่านั้น** (ห้ามบันทึกงาน review ด้วยสายตา, งานเอกสาร/wiki หรืองานทั่วไป — งานเหล่านั้นลงใน `.agents/log.md`):

```text
tests_all/tests_report/
├── README.md                 # ผังศูนย์กลางรายงาน + GAP ที่ทราบ
├── automate_tests/
│   ├── README.md             # กฎการบันทึก (ผลรันจริง + ภาษาไทย 4 มิติ)
│   ├── server/               # ผลรัน Backend/API (api_suite, admin_api, qwen_xai, risk_calculator_hybrid, scan_xai_gpu, CI)
│   ├── mobile/               # ผลรัน Mobile (api_base_url_env, history_refresh_fix, result_factors, xai_integration)
│   ├── admin/                # GAP — ยังไม่มีรายงาน automate ของ Admin Portal
│   └── model/                # GAP — ยังไม่มีรายงาน automate ของ Model
└── manual_tests/
    └── execution_log.md      # ผลรัน manual พร้อม Pass Rate ที่คำนวณได้
```

- **ภาษา:** รายงานทุกไฟล์ต้องเขียนเป็นภาษาไทย (คงคำเทคนิค คำสั่ง และ code identifier เป็นภาษาอังกฤษ)
- **รูปแบบรายงาน:** ห้ามเขียนแค่ "PASS/FAIL" อย่างเดียว ต้องแจกแจง 4 มิติเป็นภาษาไทย: (1) อะไรผ่านบ้าง (2) ผ่านอย่างไร/ทำไม (3) อะไรไม่ผ่านบ้าง (4) ไม่ผ่านอย่างไร/สาเหตุ พร้อม Expected vs Actual และ stack trace กรณี fail
- **GAP ที่ทราบ:** `automate_tests/admin/` และ `automate_tests/model/` ยังไม่มีรายงานผลรันจริง — ต้องรันสคริปต์จริงก่อนจึงบันทึก (ดู `tests_all/tests_report/README.md`)

---

## ประเด็นสำคัญ

- ตาราง manual test ทุกไฟล์ใช้ 10 คอลัมน์ตาม IEEE 829 / ISTQB โดย md เป็น canonical และ CSV ใน `spreadsheets/<area>/` ต้องสร้างใหม่ทุกครั้งที่ md เปลี่ยน
- ยอดเคสรวม: admin 25, ai_model 24, backend 32, mobile 43, nfr 23, image_testset 6, e2e 10 scenarios + 4 กลุ่ม traceability
- ผลการรันจริงเท่านั้นที่อยู่ใน `tests_all/tests_report/` และต้องแจกแจง 4 มิติเป็นภาษาไทย

---

## หน้าที่เกี่ยวข้อง

- [[requirements/traceability-matrix|เมทริกซ์การสืบย้อนความต้องการ (Traceability Matrix)]]
- [[requirements/functional-requirements|ความต้องการเชิงฟังก์ชัน]]
- [[requirements/non-functional-requirements|ความต้องการที่ไม่ใช่เชิงฟังก์ชัน]]
- [[overview|ภาพรวมโปรเจคทั้งหมด]]
- [[planning/task-tracking|การติดตามงานและการบริหารโครงการ]]
