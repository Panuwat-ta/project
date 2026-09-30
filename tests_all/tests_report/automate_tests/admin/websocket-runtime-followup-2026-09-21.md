# ผลทดสอบ Admin WebSocket Runtime Follow-up

## 2026-09-21 18:06 +07 - WebSocket connection lifecycle

- Target: `admin-portal/tests/websocket-security.test.mjs`
- Command: `node --test --test-isolation=none --test-reporter=spec tests/websocket-security.test.mjs`
- Result: PASS
- Summary: Total: 4 | Passed: 4 | Failed: 0 | Skipped: 0 | Duration: 14.31 ms
- Requirement/TC mapping: TC IDs: `TC-ADM-WS-01` | Requirement IDs: `FR-ADM-01`
- Commit/Build/Env: ไม่ได้บันทึก metadata ครบในผลรันเดิม; ห้ามอนุมานย้อนหลัง

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **WebSocket URL never carries an access token query parameter**:
  - Verification & Runtime Behavior: URL builder ไม่มี `?token=` และไม่ส่ง token เข้า `getWebSocketUrl()`
- **dashboard hook delegates connection lifecycle to the tested controller**:
  - Verification & Runtime Behavior: hook มอบ lifecycle ให้ controller และไม่มีการสร้าง `WebSocket` ซ้ำใน hook
- **dashboard WebSocket authenticates, reconnects once, and ignores stale events**:
  - Verification & Runtime Behavior: Fake WebSocket ได้ protocol `["scamguard-admin", token]`; error สร้าง reconnect timer เดียว, stale event ไม่กระทบ socket ใหม่ และ cleanup ไม่สร้าง timer เพิ่ม
- **missing access token keeps only one retry timer and cleanup cancels it**:
  - Verification & Runtime Behavior: เมื่อไม่มี token มี retry timer 2 วินาทีเพียงรายการเดียวและ cleanup ยกเลิกได้

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
