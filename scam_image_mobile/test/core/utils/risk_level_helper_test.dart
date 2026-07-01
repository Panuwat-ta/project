import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/utils/risk_level_helper.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  group('RiskLevelHelper.fromScore', () {
    // ── Low boundary (0-39) ───────────────────────────────────────────────

    test('score 0 → RiskLevel.low', () {
      expect(RiskLevelHelper.fromScore(0), RiskLevel.low);
    });

    test('score 1 → RiskLevel.low', () {
      expect(RiskLevelHelper.fromScore(1), RiskLevel.low);
    });

    test('score 39 → RiskLevel.low (upper boundary of low)', () {
      expect(RiskLevelHelper.fromScore(39), RiskLevel.low);
    });

    // ── Medium boundary (40-69) ───────────────────────────────────────────

    test('score 40 → RiskLevel.medium (lower boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(40), RiskLevel.medium);
    });

    test('score 55 → RiskLevel.medium (mid-range)', () {
      expect(RiskLevelHelper.fromScore(55), RiskLevel.medium);
    });

    test('score 69 → RiskLevel.medium (upper boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(69), RiskLevel.medium);
    });

    // ── High boundary (70-100) ────────────────────────────────────────────

    test('score 70 → RiskLevel.high (lower boundary of high)', () {
      expect(RiskLevelHelper.fromScore(70), RiskLevel.high);
    });

    test('score 85 → RiskLevel.high (mid-range)', () {
      expect(RiskLevelHelper.fromScore(85), RiskLevel.high);
    });

    test('score 100 → RiskLevel.high (max)', () {
      expect(RiskLevelHelper.fromScore(100), RiskLevel.high);
    });
  });

  group('RiskLevelHelper.toThaiLabel', () {
    test('RiskLevel.low → "ต่ำ"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.low), 'ต่ำ');
    });

    test('RiskLevel.medium → "ปานกลาง"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.medium), 'ปานกลาง');
    });

    test('RiskLevel.high → "สูง"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.high), 'สูง');
    });
  });
}
