from __future__ import annotations

import argparse
import csv
import hashlib
from pathlib import Path

from PIL import Image

EXTS = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tif', '.tiff'}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def decoded_hash(path: Path) -> tuple[str, int, int, str, str]:
    with Image.open(path) as im:
        rgb = im.convert('RGB')
        w, h = rgb.size
        exif = im.getexif()
        make = str(exif.get(271, '')).strip()
        model = str(exif.get(272, '')).strip()
        payload = f'RGB:{w}x{h}:'.encode() + rgb.tobytes()
    return hashlib.sha256(payload).hexdigest(), w, h, make, model

def scan_hashes(root: Path) -> tuple[set[str], set[str]]:
    byte_hashes, pixel_hashes = set(), set()
    if not root.exists():
        return byte_hashes, pixel_hashes
    for path in sorted(p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in EXTS):
        try:
            byte_hashes.add(sha256_file(path))
            pixel_hashes.add(decoded_hash(path)[0])
        except Exception:
            pass
    return byte_hashes, pixel_hashes


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--input-dir', required=True, type=Path)
    ap.add_argument('--output-csv', required=True, type=Path)
    ap.add_argument('--holdout-dir', type=Path,
                    default=Path('/home/panuwat/Pictures/Test-Cases/image-Authentic'))
    args = ap.parse_args()

    holdout_bytes, holdout_pixels = scan_hashes(args.holdout_dir)
    files = sorted(p for p in args.input_dir.rglob('*')
                   if p.is_file() and p.suffix.lower() in EXTS)
    rows = []
    seen_bytes, seen_pixels = set(), set()
    for path in files:
        row = {'path': str(path), 'status': 'ok', 'reason': '',
               'sha256': '', 'decoded_sha256': '', 'width': '', 'height': '',
               'megapixels': '', 'exif_make': '', 'exif_model': '',
               'holdout_overlap': 0, 'duplicate_incoming': 0}
        try:
            bh = sha256_file(path)
            ph, w, h, make, model = decoded_hash(path)
            row.update({'sha256': bh, 'decoded_sha256': ph, 'width': w, 'height': h,
                        'megapixels': round(w * h / 1_000_000, 6),
                        'exif_make': make, 'exif_model': model})
            if bh in holdout_bytes or ph in holdout_pixels:
                row['status'] = 'exclude'
                row['reason'] = 'matches_protected_image_authentic_holdout'
                row['holdout_overlap'] = 1
            elif bh in seen_bytes or ph in seen_pixels:
                row['status'] = 'exclude'
                row['reason'] = 'duplicate_within_incoming'
                row['duplicate_incoming'] = 1
            seen_bytes.add(bh); seen_pixels.add(ph)
        except Exception as exc:
            row['status'] = 'exclude'
            row['reason'] = f'decode_error:{type(exc).__name__}'
        rows.append(row)

    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    fields = list(rows[0].keys()) if rows else ['path', 'status', 'reason']
    with args.output_csv.open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(rows)
    ok = sum(r['status'] == 'ok' for r in rows)
    excluded = len(rows) - ok
    holdout = sum(int(r.get('holdout_overlap', 0)) for r in rows)
    duplicates = sum(int(r.get('duplicate_incoming', 0)) for r in rows)
    print(f'files={len(rows)} ok={ok} excluded={excluded} '
          f'holdout_overlap={holdout} duplicate_incoming={duplicates}')
    print(args.output_csv)


if __name__ == '__main__':
    main()
