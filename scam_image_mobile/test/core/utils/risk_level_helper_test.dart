import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/utils/risk_level_helper.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  group('RiskLevelHelper.fromScore', () {
    // ── Safe boundary (0-39) ───────────────────────────────────────────────

    test('score 0 → RiskLevel.safe', () {
      expect(RiskLevelHelper.fromScore(0), RiskLevel.safe);
    });

    test('score 1 → RiskLevel.safe', () {
      expect(RiskLevelHelper.fromScore(1), RiskLevel.safe);
    });

    test('score 39 → RiskLevel.safe (upper boundary of safe)', () {
      expect(RiskLevelHelper.fromScore(39), RiskLevel.safe);
    });

    // ── Low boundary (40-59) ───────────────────────────────────────────

    test('score 40 → RiskLevel.low (lower boundary of low)', () {
      expect(RiskLevelHelper.fromScore(40), RiskLevel.low);
    });

    test('score 50 → RiskLevel.low (mid-range)', () {
      expect(RiskLevelHelper.fromScore(50), RiskLevel.low);
    });

    test('score 59 → RiskLevel.low (upper boundary of low)', () {
      expect(RiskLevelHelper.fromScore(59), RiskLevel.low);
    });

    // ── Medium boundary (60-79) ────────────────────────────────────────────

    test('score 60 → RiskLevel.medium (lower boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(60), RiskLevel.medium);
    });

    test('score 70 → RiskLevel.medium (mid-range)', () {
      expect(RiskLevelHelper.fromScore(70), RiskLevel.medium);
    });

    test('score 79 → RiskLevel.medium (upper boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(79), RiskLevel.medium);
    });

    // ── High boundary (80-100) ────────────────────────────────────────────

    test('score 80 → RiskLevel.high (lower boundary of high)', () {
      expect(RiskLevelHelper.fromScore(80), RiskLevel.high);
    });

    test('score 90 → RiskLevel.high (mid-range)', () {
      expect(RiskLevelHelper.fromScore(90), RiskLevel.high);
    });

    test('score 100 → RiskLevel.high (max)', () {
      expect(RiskLevelHelper.fromScore(100), RiskLevel.high);
    });
  });

  group('RiskLevelHelper.toThaiLabel', () {
    test('RiskLevel.safe → "ปลอดภัย"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.safe), 'ปลอดภัย');
    });

    test('RiskLevel.low → "เสี่ยงต่ำ"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.low), 'เสี่ยงต่ำ');
    });

    test('RiskLevel.medium → "เสี่ยง"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.medium), 'เสี่ยง');
    });

    test('RiskLevel.high → "เสี่ยงสูง"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.high), 'เสี่ยงสูง');
    });
  });
}
