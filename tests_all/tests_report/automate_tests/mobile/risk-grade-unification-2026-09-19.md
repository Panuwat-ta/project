## 2026-09-19 03:10 +07 - [Risk Grade Unification / Mobile full suite]

- Target: scam_image_mobile/test/ ทั้งชุด (เน้น risk_level_helper, risk_badge, analysis_result_model, scan_history_item_model)
- Command: `flutter test` (workdir: `scam_image_mobile/`)
- Result: FAIL (เฉพาะ 2 เคสเดิมที่ไม่เกี่ยวกับงานนี้ — พิสูจน์แล้วว่า fail บน clean tree ด้วย)
- Summary: Total: 232 | Passed: 230 | Failed: 2 | Skipped: 0 | Duration: ~10 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[RiskLevelHelper.factorLevelForScore (13 เคส, ย้ายชื่อจาก fromScore)]**:
  - พฤติกรรมที่ผ่าน: mapping 0-39 low / 40-69 medium / 70-100 high เหมือนเดิมทุก boundary ยืนยันว่า factor pill แสดงผลเหมือนเดิม
- **[unknown mappers (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: `toIcon(unknown)` ได้ help icon, `toThaiLabel` ได้ Unknown, `toLabelKey` ได้ result_unknown_risk, `toColor` ได้ grey — ไม่มี mapper ใดคืนค่าสี/ป้ายของ low/medium/high
- **[AnalysisResultModel.fromJson canonical (ปรับใหม่)]**:
  - พฤติกรรมที่ผ่าน: อ่าน `total_risk_score` + `risk_grade` ได้ high/medium/low ถูกต้อง, grade หายได้ unknown, grade แปลก (critical) ได้ unknown, key camelCase เดิมถูก ignore (riskScore 0 + unknown)
- **[ScanHistoryItemModel.fromJson canonical (ปรับใหม่)]**:
  - พฤติกรรมที่ผ่าน: อ่าน `risk_score` + `risk_level` ได้ถูกต้อง, grade หายได้ unknown แทน high เดิม (ปิด fail-dangerous default)
- **[RiskBadge unknown widget + levelFromString (ปรับใหม่)]**:
  - พฤติกรรมที่ผ่าน: badge unknown แสดง "ไม่ทราบ" สีเทา, `levelFromString('safe'/'unknown')` ได้ unknown แทน low เดิม
- **[เคสอื่นทั้งชุด (history/result bloc, screens, datasource)]**:
  - พฤติกรรมที่ผ่าน: ผ่านทั้งหมด ไม่มี regression จากการเพิ่ม enum value และการรวม enum ซ้ำของ RiskBadge เข้ากับ domain enum

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- **[scan_bloc_test: AnalysisCancelled emits ScanInitial...]**:
  - สาเหตุที่ไม่ผ่าน: fail อยู่ก่อนแล้วบน clean tree (verify ด้วย `git stash` แล้วรันซ้ำ ยัง fail เหมือนเดิม) เกี่ยวกับ cancelScan/task lifecycle ไม่เกี่ยวกับ RiskLevel งานนี้ไม่ได้แตะไฟล์ `scan_bloc`
- **[scan_bloc_test: CropConfirmed emits [ScanUploading, ScanPolling]...]**:
  - สาเหตุที่ไม่ผ่าน: เช่นเดียวกัน เป็นของเดิมบน clean tree เกี่ยวกับ submitImage/polling transition ไม่เกี่ยวกับงานนี้
