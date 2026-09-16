# QA Loop State — Admin Portal (usage + correctness)

Runner: `.impeccable/qa-loop/run.sh` · Skill: `admin-portal-qa` · Cadence: daily
Stop condition (machine-checkable): clean tree + lint 0 errors + tests all pass +
build succeeds + no JS chunk over 500 kB + live contracts 10/10 PASS.
Cost guard: 1 retry per gate, hard timeouts per gate, pause after 3 straight FAILs
(quality gates only), overlapping runs serialize via lock (exit 2 = skip).

- paused: false

Last run: 25690916-161449 — FAIL (failed gates: 2)

## Triage inbox

- [ ] Backend :8000 down ตั้งแต่ ~16:14 (run 161449: `backend-unreachable`, ยืนยันซ้ำ 16:2x) — live gate จะ FAIL ทุกวันจนกว่า backend กลับมา. ตัดสินใจ: ใคร restart backend (server/run.sh) และเมื่อไร.

## History

- 25690916-161449: FAIL = dirty-tree (expected, informational) + backend down (environment). Verifier อิสระ re-run ยืนยัน exit-code semantics ถูกต้อง (exit 1 + evidence + triage ครบ).
- 25690916-160153: คุณภาพ 5/5 PASS (lint/tests/build/chunks/live 10 schemas) — baseline green ตัวแรก; เหลือแค่ dirty-tree เพราะ rebuild ยังไม่ commit.
- 25690916-160446: tests FAIL 1 เคส (login test timeout) จากรันซ้อนกัน 2 loop พร้อมกัน (CPU contention) — แก้แล้วด้วย flock guard ใน run.sh, ทดสอบแล้วว่า SKIP + exit 2.
- 25690916-155904: FAIL = dirty-tree (expected) + live-check บั๊ก path (ROOT เกิน 1 ชั้น → missing-dev-credentials) — แก้แล้ว (revert เป็น `../../..`), รันถัดไป live PASS.
- 2026-09-16: loop created (skill admin-portal-qa, cron admin-portal-daily-qa ทุกวัน 06:30, deliver local).
