#!/usr/bin/env python3
"""Purge scans เกินอายุ + ไฟล์รูป (retention: 90 วัน).

- ลบ row ใน scans ที่ created_at เก่ากว่า cutoff (default 90 วัน)
- ลบไฟล์ raw/heatmap จาก disk ด้วย (เฉพาะไฟล์ใต้ LOCAL_UPLOAD_DIR กัน path traversal)
- scam_reports ที่อ้าง scan นั้นอยู่ต่อแบบ scan_id NULL (ตาม FK ON DELETE SET NULL)
- ใช้กับ cron: 0 3 * * * .../venv/bin/python .../scripts/purge_old_scans.py --days 90
"""
import argparse
import os
import sys
from datetime import datetime, timedelta, timezone

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import asyncio
from pathlib import Path
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.database import engine
from app.models.scan import Scan


def safe_unlink(raw_path: str, upload_dir: Path) -> bool:
    """ลบไฟล์เฉพาะที่อยู่ใต้ upload_dir จริง (resolve กัน ../ หลุดออกนอก dir)."""
    try:
        p = (Path(raw_path).expanduser() if os.path.isabs(raw_path)
             else upload_dir / raw_path).resolve()
        if not p.is_relative_to(upload_dir):
            print(f'  SKIP (นอก upload dir): {raw_path}')
            return False
        p.unlink(missing_ok=True)
        return True
    except Exception as ex:
        print(f'  SKIP (ลบไม่ได้ {raw_path}): {ex}')
        return False


async def purge(days: int, dry_run: bool, batch_size: int) -> dict:
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    upload_dir = Path(settings.LOCAL_UPLOAD_DIR).expanduser().resolve()
    stats = {'scans': 0, 'files': 0}
    maker = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with maker() as db:
        while True:
            result = await db.execute(
                select(Scan).where(Scan.created_at < cutoff)
                .order_by(Scan.created_at).limit(batch_size))
            scans = result.scalars().all()
            if not scans:
                break
            ids = []
            for s in scans:
                ids.append(s.id)
                stats['scans'] += 1
                if dry_run:
                    continue
                for path in (s.raw_image_url, s.heatmap_image_url):
                    if path and safe_unlink(path, upload_dir):
                        stats['files'] += 1
            if not dry_run:
                await db.execute(delete(Scan).where(Scan.id.in_(ids)))
                await db.commit()
    return stats


async def main() -> int:
    ap = argparse.ArgumentParser(description='Purge scans + ไฟล์รูปที่เก่ากว่า N วัน')
    ap.add_argument('--days', type=int, default=90)
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--batch-size', type=int, default=500)
    args = ap.parse_args()

    stats = await purge(args.days, args.dry_run, args.batch_size)
    mode = 'DRY-RUN ' if args.dry_run else ''
    print(f'{mode}done: scans={stats["scans"]} files_removed={stats["files"]} (>{args.days}d)')
    return 0


if __name__ == '__main__':
    raise SystemExit(asyncio.run(main()))
