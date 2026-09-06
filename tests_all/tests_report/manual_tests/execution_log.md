# บันทึกผลการทดสอบแบบ Manual (Manual Test Execution Log)

- โครงการ: ScamGuard (Scam Image Detection System)
- ตำแหน่งไฟล์: tests_all/tests_report/manual_tests/execution_log.md
- อ้างอิงชุดทดสอบ: tests_all/manual_tests/test_cases_mobile.md, test_cases_backend.md, test_cases_ai_model.md, test_cases_admin.md, test_cases_e2e.md, test_cases_nfr.md
- อ้างอิงแผนหลัก: Document/tests_doc/test_plan/README.md ส่วนที่ 5 เกณฑ์การเริ่ม ระงับ และสิ้นสุดการทดสอบ
- อ้างอิงความครอบคลุม: tests_all/rtm.md
- สถานะโฟลเดอร์นี้ก่อนสร้างไฟล์: ว่าง ไม่มีบันทึกผล manual ใดใด มีเฉพาะผล automate ใน tests_all/tests_report/automate_tests/server และ mobile

---

## 1. วัตถุประสงค์

ใช้บันทึกผลการรันทดสอบ manual จริงทีละรอบ แยกออกจากผล automate ที่อยู่ใน tests_all/tests_report/automate_tests อย่างชัดเจน ทุกรายการต้องมาจากการลงมือทดสอบจริงบนอุปกรณ์หรือคอนโซลจริง ไม่ใช่การอ่านเอกสารหรือตรวจด้วยสายตา

---

## 2. วิธีใช้

1. ก่อนเริ่มรอบทดสอบ ตรวจสอบ Entry Criteria ตามแผนหลัก ได้แก่ Environment ครบ (PostgreSQL, Redis, Backend API, Admin Portal) อยู่ในสถานะ Healthy, Build และ Lint ผ่านโดยไม่มีข้อผิดพลาด, รัน Alembic Migration ล่าสุดแล้ว, คอนฟิกโหลดจากไฟล์ .env สำเร็จ
2. เลือก TC ID จากไฟล์ใน tests_all/manual_tests ให้ตรง Requirement ID ใน rtm.md ห้ามสมมติ TC ที่ไม่มีอยู่จริง
3. ทดสอบทีละ TC แล้วบันทึก 1 แถวต่อ 1 TC ต่อ 1 รอบทันที ห้ามรวมหลายรอบในแถวเดียว
4. ถ้ารันซ้ำให้เพิ่มแถวใหม่พร้อมวันที่ใหม่ ห้ามเขียนทับแถวเดิม
5. ถ้าผลเป็น Fail ให้เปิด Bug ตามแบบฟอร์ม tests_all/bug_report_template.md แล้วนำเลข Bug ID มากรอกในช่องหมายเหตุ
6. ถ้าเป็น TC กลุ่มถดถอย (TC-BE-REG-01, TC-MOB-REG-01, TC-E2E-REG-09, TC-AI-REG-01) ให้ระบุว่าเป็นรอบ Retest หรือ Regression ในช่องหมายเหตุด้วย
7. เมื่อครบรอบ ให้นำสรุป Pass Rate ไปเทียบกับ Exit Criteria ในไฟล์ tests_all/release_signoff.md ก่อนลงนามปล่อยเวอร์ชัน

---

## 3. ตารางบันทึกผล (กรอกเพิ่มทีละแถว ห้ามลบแถวเก่า)

| TC ID | วันที่ (ปปปป-ดด-วว) | ผู้ทดสอบ | อุปกรณ์และสภาพแวดล้อม | ผล (Pass Fail Blocked Skipped) | หมายเหตุ (Bug ID / รอบ Retest / GAP) |
|---|---|---|---|---|---|
| ตัวอย่าง TC-MOB-AUTH-01 | 2026-09-06 | ชื่อผู้ทดสอบ | Pixel 6 Android 14 แอปบิลด์ staging ต่อ Backend staging | Pass | รอบ Smoke ครั้งที่ 1 |
| ตัวอย่าง TC-BE-SCAN-01 | 2026-09-06 | ชื่อผู้ทดสอบ | Backend Port 8000 ต่อ PostgreSQL 5432 และ Redis 6379 | Fail | เปิด BUG-001 แล้ว รอแก้ |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |

---

## 4. ความหมายของค่าที่กรอก

- TC ID: รหัสกรณีทดสอบตามไฟล์ tests_all/manual_tests เช่น TC-MOB-AUTH-01, TC-BE-REG-01, TC-E2E-REG-09
- วันที่: วันที่ลงมือทดสอบจริง ใช้รูปแบบปีเดือนวันเพื่อเรียงลำดับได้
- ผู้ทดสอบ: ชื่อย่อหรือชื่อเต็มของผู้ลงมือทดสอบ เพื่อสอบย้อนได้ว่าใครเป็นพยานผล
- อุปกรณ์และสภาพแวดล้อม: รุ่นอุปกรณ์ เวอร์ชัน OS หรือเบราว์เซอร์ ฝั่ง Backend ระบุพอร์ตและฐานข้อมูลที่ใช้ ฝั่ง Mobile ระบุรุ่นเครื่อง (เช่น Pixel 6, Galaxy S21, Emulator API 33 หรือ 34 ตามแผนหลัก) ฝั่ง Admin ระบุเบราว์เซอร์และ URL ของ Portal
- ผล: Pass หมายถึงตรง Expected ทุกข้อ, Fail หมายถึงมีข้อใดไม่ตรงและเปิด Bug แล้ว, Blocked หมายถึงติด Suspension Criteria (เช่น Database ต่อไม่ได้, AI worker ล่ม, เจอ P0 Blocker) จนทดสอบต่อไม่ได้, Skipped หมายถึงข้ามอย่างมีเหตุผล (เช่น Deferred OAuth หรือ FCM Phase 2)
- หมายเหตุ: ใส่เลข Bug, ระบุว่าเป็นรอบ Retest ครั้งที่เท่าใด, อ้างอิง REG TC ที่ใช้ตรวจซ้ำ, หรือระบุ GAP/Deferred ตาม rtm.md

---

## 5. สรุปรอบทดสอบ (กรอก 1 ชุดต่อ 1 รอบ)

- รอบที่: ระบุครั้งที่และช่วงวันที่
- ขอบเขตรอบนี้: ระบุโมดูลและรายการ TC ที่รัน เช่น Mobile Auth 10 TC, Backend Scan 8 TC, Regression 4 TC
- สรุปจำนวน: ทั้งหมดกี่ TC, Pass กี่ TC, Fail กี่ TC, Blocked กี่ TC, Skipped กี่ TC พร้อมคิด Pass Rate แยก P0 P1 P2
- รายการ Fail และ Bug ที่เปิด: ระบุ TC ID คู่กับ Bug ID ทุกรายการ
- รายการ Blocked และสาเหตุ: อ้างอิง Suspension Criteria ในแผนหลัก
- ข้อสังเกต GAP/Deferred ที่พบในรอบนี้: เช่น FR-SYS-01 EXIF ไม่มี TC, FR-AUTH-03 OAuth เป็น Deferred
- ผู้สรุปและวันที่สรุป: ชื่อและวันที่

---

## 6. กฎการบันทึก

1. เก็บเฉพาะผลรันจริงเท่านั้น ห้ามบันทึกการอ่านเอกสารหรือการตรวจด้วยสายตาเป็นผล Pass
2. ภาษาไทยเป็นหลัก คงชื่อฟังก์ชัน เส้น API ชื่อตาราง ชื่อคอลัมน์ และศัพท์เทคนิคเป็นภาษาอังกฤษตามเดิม
3. ห้ามใช้ Emoji ในไฟล์นี้และไฟล์รายงานทั้งหมด
4. หนึ่ง TC ต่อหนึ่งแถวต่อหนึ่งรอบ รันซ้ำต้องเพิ่มแถวใหม่พร้อมวันที่ใหม่
5. ผล Fail ทุกแถวต้องมี Bug ID กำกับ ผล Blocked ต้องมีสาเหตุอ้างอิงเกณฑ์ระงับในแผนหลัก
