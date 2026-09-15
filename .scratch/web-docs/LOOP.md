# LOOP: web-docs real build (run-until-done)

## Automation
- Trigger: event — ทุกครั้งที่ maker จบ (async completion) → dispatcher (หลัก) ตรวจแล้วส่ง loop ถัดไป
- ไม่มี cron/polling

## Worktrees
- ไม่ใช้ (loops รันทีละตัวตามลำดับ ไม่ขนานบนไฟล์ชุดเดียวกัน) — ถ้าขนานในอนาคตต้องแยก worktree ก่อน

## Skills (เรียกด้วยชื่อ)
- creative/impeccable, bilingual-static-sites, implement, tdd, code-review

## Plugins/connectors
- ไม่มีภายนอก (git + filesystem เท่านั้น)

## Sub-agents (maker ≠ checker)
- maker: subagent ต่อ loop | checker: dispatcher ตรวจหลักฐานเอง (ls/grep/curl/exit codes) ก่อนส่งต่อ

## Memory/state (ไฟล์นี้)
- [x] Loop 1 — design lock (DESIGN.md + commit 00e76a8; maker report ว่างแต่ checker ตรวจของครบ)
- [x] Loop 2 — build pipeline TDD (build.py + check-i18n + overview.html + commit 4c0beeb)
- [x] Loop 3 — all content (44 หน้า + i18n EN-WIP + commit 7c0650a)
- [ ] Loop 4 — root index verify (curl 200, ไม่ commit ถ้าไม่เปลี่ยน)
- [ ] Loop 5 — code-review 2 แกน (Standards + Spec)

## Stop conditions (checker ตรวจ)
- ครบ 5 loops + review ไม่มี hard violation → STOP เสนอ merge
- maker ล้ม 2 รอบติด loop เดียวกัน → STOP แจ้งคน (ไม่ retry รอบ 3)
- Cost ceiling: สูงสุด 15 subagent calls ตลอดลูป

## Log
- 2026-09-15: loop created, Loop 1 dispatched
