import { describe, expect, it } from 'vitest';
import { sortQueue } from './dashboard-queries.js';

function report(id, score, created) {
  return {
    id,
    created_at: created,
    scan: score === null ? null : { total_risk_score: score, risk_grade: 'high' },
  };
}

describe('sortQueue', () => {
  it('เรียงตามคะแนนมากไปน้อย คะแนนเท่ากันเอาเก่าก่อน ไม่มี scan อยู่ท้าย', () => {
    const items = [
      report(1, 58, '2026-09-16T08:00:00Z'),
      report(2, 92, '2026-09-16T09:00:00Z'),
      report(3, null, '2026-09-16T07:00:00Z'),
      report(4, 92, '2026-09-16T07:30:00Z'),
      report(5, 41, '2026-09-16T10:00:00Z'),
    ];
    const sorted = sortQueue(items);
    expect(sorted.map((r) => r.id)).toEqual([4, 2, 1, 5, 3]);
  });

  it('ไม่ mutate array ต้นฉบับ', () => {
    const items = [report(1, 10, '2026-09-16T08:00:00Z'), report(2, 90, '2026-09-16T08:00:00Z')];
    sortQueue(items);
    expect(items[0].id).toBe(1);
  });
});
