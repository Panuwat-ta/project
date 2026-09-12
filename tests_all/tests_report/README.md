# ศูนย์กลางรายงานผลการรันทดสอบ (`tests_report/`)

ไดเรกทอรีนี้เก็บ **ผลการรันทดสอบจริงเท่านั้น** แยกตามประเภทการรัน รายละเอียดกฎการบันทึกดูที่ `automate_tests/README.md` (ผลรันจริง + ภาษาไทย 4 มิติเท่านั้น ห้าม log งาน agent)

---

## โครงสร้าง

```text
tests_all/tests_report/
├── README.md                 # ไฟล์นี้ — แผนผังศูนย์กลางรายงาน
├── automate_tests/
│   ├── README.md             # กฎการบันทึกรายงาน (ผลรันจริงเท่านั้น + ภาษาไทย 4 มิติ)
│   ├── server/               # ผลรันฝั่ง Backend/AI (api_suite, admin_api, qwen_xai, risk_calculator_hybrid, scan_xai_gpu, CI)
│   │   └── archive/          # รายงานของสูตร/สิ่งที่เลิกใช้แล้ว (risk_calculator_weights.md — สูตร Weighted เดิม)
│   ├── mobile/               # ผลรันฝั่ง Mobile (api_base_url_env, history_refresh_fix, result_factors, xai_integration)
│   ├── admin/                # GAP — ยังไม่มีรายงาน automate ของ Admin Portal
│   └── model/                # GAP — ยังไม่มีรายงาน automate ของ Model
└── manual_tests/
    └── execution_log.md      # ผลรัน manual พร้อม Pass Rate ที่คำนวณได้
```

---

## เจ้าของและกำหนดส่ง (Owner/Due — ผูกเป็นเงื่อนไขบล็อกปล่อย)

| โฟลเดอร์ที่ค้าง | Owner | Due | เงื่อนไขปล่อย |
| :--- | :--- | :--- | :--- |
| `automate_tests/admin/` | QA Lead (กรอกชื่อ) | ก่อน sign-off รอบถัดไป (กรอกวันที่) | บล็อกการปล่อยจนกว่าจะมีรายงานผลรันจริง หรือมี compensating evidence ที่ QA+PM ลงนาม |
| `automate_tests/model/` | AI Owner (กรอกชื่อ) | ก่อน sign-off รอบถัดไป (กรอกวันที่) | เช่นเดียวกัน |

## ตัวชี้วัดรอบล่าสุด (Latest metrics — กรอกเมื่อมีผลรันจริง ห้ามแต่งตัวเลข)

| รอบ (วันที่) | Manual pass rate | Automate server | Automate mobile | หมายเหตุ |
| :--- | :--- | :--- | :--- | :--- |
| (ยังไม่มี — กรอกเมื่อมีผลรันจริง) | — | — | — | — |

## GAP ที่ทราบ (Known Gaps)

- `automate_tests/admin/` และ `automate_tests/model/` ยังไม่มีรายงานผลรัน — ต้องรันสคริปต์จริงก่อนจึงบันทึก (ห้ามบันทึก review ด้วยสายตา)
- รายงานใน `server/archive/` เป็นประวัติของสูตรเก่า (Weighted) ที่ถูกแทนด้วยสูตร Hybrid (max+bonus) แล้ว — สูตรทางการดูที่ RTM และ SRS ปัจจุบัน
