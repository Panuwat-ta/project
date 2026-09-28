#!/usr/bin/env python3
"""Summarize Det Head shadow telemetry JSONL without touching user-facing state."""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def percentile(values, q):
    if not values:
        return None
    xs = sorted(float(v) for v in values)
    if len(xs) == 1:
        return xs[0]
    pos = (len(xs) - 1) * q
    lo, hi = int(pos), min(int(pos) + 1, len(xs) - 1)
    frac = pos - lo
    return xs[lo] * (1 - frac) + xs[hi] * frac


def load_events(path: Path):
    events, bad = [], 0
    if not path.exists():
        return events, bad
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            bad += 1
    return events, bad


def summarize(events, bad_lines):
    valid = [e for e in events if e.get("det_score") is not None]
    fresh = [e for e in events if not e.get("cache_hit")]
    latency = [e.get("onnx_latency_ms") for e in fresh if e.get("onnx_latency_ms") is not None]
    groups = {"both_low": 0, "both_high": 0, "seg_high_det_low": 0, "seg_low_det_high": 0}
    disagreements = []
    for e in valid:
        seg = float(e.get("ai_gen_probability") or 0.0) >= 0.5
        det = float(e["det_score"]) >= 0.5
        key = "both_high" if seg and det else "both_low" if not seg and not det else "seg_high_det_low" if seg else "seg_low_det_high"
        groups[key] += 1
        if seg != det:
            disagreements.append(e)
    disagreements.sort(key=lambda e: abs(float(e.get("det_score") or 0) - float(e.get("ai_gen_probability") or 0)), reverse=True)
    cuda = sum("CUDAExecutionProvider" in (e.get("onnx_execution_providers") or []) for e in fresh)
    return {
        "events": len(events), "bad_lines": bad_lines,
        "unique_scans": len({e.get("scan_id") for e in events}),
        "det_available": len(valid), "cache_hits": sum(bool(e.get("cache_hit")) for e in events),
        "worker_timeouts": sum(bool(e.get("onnx_worker_timed_out")) for e in events),
        "fresh_cuda_events": cuda, "fresh_events": len(fresh),
        "latency_ms_p50": percentile(latency, 0.50), "latency_ms_p95": percentile(latency, 0.95),
        "agreement": groups, "disagreement_count": len(disagreements),
        "top_disagreements": disagreements[:10],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", default="logs/shadow/det_head.jsonl")
    ap.add_argument("--output", default="logs/shadow/det_head_summary.json")
    args = ap.parse_args()
    events, bad = load_events(Path(args.path))
    summary = summarize(events, bad)
    out = Path(args.output); out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
