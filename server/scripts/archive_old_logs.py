#!/usr/bin/env python3
"""Archive audit_log + consent_logs เกินอายุ retention (default 365 วัน).

- ย้าย row เก่า -> *_archive (เก็บ archived_at) แล้วลบจากตารางจริงเป็น batch
- audit_log มี trigger append-only: script ตั้ง SET LOCAL app.allow_audit_archive='on'
  ใน transaction เดียวกัน (transaction-scoped, ไม่รั่วข้าม session; app ไม่เคยตั้งค่านี้)
- ใช้กับ cron รายเดือน: 0 4 1 * * .../venv/bin/python .../scripts/archive_old_logs.py
"""
import argparse
import os
import sys
from datetime import datetime, timedelta, timezone

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import asyncio
from sqlalchemy import text, bindparam
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings

AUDIT_COLS = (
    'id, admin_id, action, entity_type, entity_id, before_state, after_state, '
    'reason, ip_address, user_agent, request_id, details, created_at'
)
CONSENT_COLS = (
    'id, user_id, system_consent, research_consent, ip_address, user_agent, created_at'
)


async def archive_table(conn, src: str, dst: str, cols: str, cutoff, batch_size: int,
                        allow_audit: bool = False) -> int:
    moved = 0
    while True:
        r = await conn.execute(
            text(f'SELECT id FROM {src} WHERE created_at < :cut '
                 f'ORDER BY created_at LIMIT :n').bindparams(cut=cutoff, n=batch_size))
        ids = [row[0] for row in r.fetchall()]
        if not ids:
            break
        if allow_audit:
            await conn.execute(text("SET LOCAL app.allow_audit_archive = 'on'"))
        await conn.execute(text(
            f'INSERT INTO {dst} ({cols}, archived_at) '
            f"SELECT {cols}, NOW() FROM {src} WHERE id IN :ids").bindparams(bindparam('ids', expanding=True)), {'ids': list(ids)})
        await conn.execute(
            text(f'DELETE FROM {src} WHERE id IN :ids').bindparams(bindparam('ids', expanding=True)), {'ids': list(ids)})
        await conn.commit()
        moved += len(ids)
    return moved


async def main() -> int:
    ap = argparse.ArgumentParser(description='Archive logs เกิน retention')
    ap.add_argument('--days', type=int, default=365)
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--batch-size', type=int, default=1000)
    args = ap.parse_args()

    cutoff = datetime.now(timezone.utc) - timedelta(days=args.days)
    e = create_async_engine(settings.DATABASE_URL)
    async with e.connect() as conn:
        if args.dry_run:
            for src in ('audit_log', 'consent_logs'):
                r = await conn.execute(
                    text(f'SELECT COUNT(*) FROM {src} WHERE created_at < :cut').bindparams(cut=cutoff))
                print(f'DRY-RUN {src}: {r.scalar()} rows older than {args.days}d')
            return 0
        a = await archive_table(conn, 'audit_log', 'audit_log_archive',
                                AUDIT_COLS, cutoff, args.batch_size, allow_audit=True)
        c = await archive_table(conn, 'consent_logs', 'consent_logs_archive',
                                CONSENT_COLS, cutoff, args.batch_size)
        print(f'done: audit_log={a} consent_logs={c} (>{args.days}d)')
    await e.dispose()
    return 0


if __name__ == '__main__':
    raise SystemExit(asyncio.run(main()))
