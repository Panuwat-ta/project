import { describe, expect, it } from 'vitest';
import {
  formatFileSize,
  formatMetric,
  formatNumber,
  formatWaitingTime,
  normalizeRiskDistribution,
  riskLevelForScore,
} from './formatters.js';

describe('formatters', () => {
  it('formatNumber ใช้ th-TH และ em dash เมื่อไม่มีข้อมูล', () => {
    expect(formatNumber(1234567)).toBe(new Intl.NumberFormat('th-TH').format(1234567));
    expect(formatNumber(null)).toBe('—');
    expect(formatNumber(undefined)).toBe('—');
  });

  it('riskLevelForScore ใช้ขอบเขต 40/70', () => {
    expect(riskLevelForScore(0)).toBe('low');
    expect(riskLevelForScore(39)).toBe('low');
    expect(riskLevelForScore(40)).toBe('medium');
    expect(riskLevelForScore(69)).toBe('medium');
    expect(riskLevelForScore(70)).toBe('high');
    expect(riskLevelForScore(100)).toBe('high');
    expect(riskLevelForScore(null)).toBe('unknown');
  });

  it('normalizeRiskDistribution ไม่สนตัวพิมพ์เล็กใหญ่', () => {
    const dist = normalizeRiskDistribution({ HIGH: 3, Medium: 4, low: 5, Critical: 2, something: 1 });
    expect(dist).toEqual({ high: 5, medium: 4, low: 5, unknown: 1 });
  });

  it('formatWaitingTime แสดงหน่วยนาที/ชั่วโมง/วัน', () => {
    const now = Date.now();
    expect(formatWaitingTime(new Date(now - 30 * 1000).toISOString())).toBe('เมื่อสักครู่');
    expect(formatWaitingTime(new Date(now - 5 * 60000).toISOString())).toContain('นาที');
    expect(formatWaitingTime(new Date(now - 2 * 3600000).toISOString())).toContain('ชม.');
    expect(formatWaitingTime(null)).toBe('—');
  });

  it('formatFileSize และ formatMetric คืน em dash/null อย่างถูกต้อง', () => {
    expect(formatFileSize(512)).toContain('B');
    expect(formatFileSize(2048)).toContain('KB');
    expect(formatFileSize(null)).toBe('—');
    expect(formatMetric(0.87654)).toBe('0.88');
    expect(formatMetric(null)).toBeNull();
  });
});
