import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/utils/risk_level_helper.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  group('RiskLevelHelper.fromScore', () {
    // -- Low boundary (0-39) -------------------------------------------

    test('score 0 -> RiskLevel.low', () {
      expect(RiskLevelHelper.fromScore(0), RiskLevel.low);
    });

    test('score 1 -> RiskLevel.low', () {
      expect(RiskLevelHelper.fromScore(1), RiskLevel.low);
    });

    test('score 19 -> RiskLevel.low (upper boundary of low low-range)', () {
      expect(RiskLevelHelper.fromScore(19), RiskLevel.low);
    });
    // -- Low boundary (20-39) -----------------------------------------

    test('score 20 -> RiskLevel.low (lower boundary of low)', () {
      expect(RiskLevelHelper.fromScore(20), RiskLevel.low);
    });

    test('score 30 -> RiskLevel.low (mid-range)', () {
      expect(RiskLevelHelper.fromScore(30), RiskLevel.low);
    });

    test('score 39 -> RiskLevel.low (upper boundary of low)', () {
      expect(RiskLevelHelper.fromScore(39), RiskLevel.low);
    });

    // -- Medium boundary (40-69) ----------------------------------------

    test('score 40 -> RiskLevel.medium (lower boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(40), RiskLevel.medium);
    });

    test('score 55 -> RiskLevel.medium (mid-range)', () {
      expect(RiskLevelHelper.fromScore(55), RiskLevel.medium);
    });

    test('score 69 -> RiskLevel.medium (upper boundary of medium)', () {
      expect(RiskLevelHelper.fromScore(69), RiskLevel.medium);
    });

    // -- High boundary (70-100) ----------------------------------------

    test('score 70 -> RiskLevel.high (lower boundary of high)', () {
      expect(RiskLevelHelper.fromScore(70), RiskLevel.high);
    });

    test('score 90 -> RiskLevel.high (mid-range)', () {
      expect(RiskLevelHelper.fromScore(90), RiskLevel.high);
    });

    test('score 100 -> RiskLevel.high (max)', () {
      expect(RiskLevelHelper.fromScore(100), RiskLevel.high);
    });
  });

  group('RiskLevelHelper.toThaiLabel', () {
    test('RiskLevel.low -> "Low"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.low), 'Low');
    });

    test('RiskLevel.medium -> "Medium"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.medium), 'Medium');
    });

    test('RiskLevel.high -> "High"', () {
      expect(RiskLevelHelper.toThaiLabel(RiskLevel.high), 'High');
    });
  });

  group('RiskLevelHelper.toColor', () {
    test('low returns tertiary yellow', () {
      expect(RiskLevelHelper.toColor(RiskLevel.low), AppColors.tertiary);
    });

    test('medium returns orange', () {
      expect(RiskLevelHelper.toColor(RiskLevel.medium), const Color(0xFFEA580C));
    });

    test('high returns danger red', () {
      expect(RiskLevelHelper.toColor(RiskLevel.high), AppColors.danger);
    });
  });

  group('RiskLevelHelper.toBgColor', () {
    test('returns different colors for light and dark mode', () {
      for (final level in RiskLevel.values) {
        final light = RiskLevelHelper.toBgColor(level, isDark: false);
        final dark = RiskLevelHelper.toBgColor(level, isDark: true);
        expect(light, isNot(equals(dark)),
            reason: '$level should have different bg colors for light/dark');
      }
    });

    test('all levels return non-null colors', () {
      for (final level in RiskLevel.values) {
        expect(RiskLevelHelper.toBgColor(level, isDark: false), isA<Color>());
        expect(RiskLevelHelper.toBgColor(level, isDark: true), isA<Color>());
      }
    });
  });

  group('RiskLevelHelper.toTextColor', () {
    test('returns different colors for light and dark mode', () {
      for (final level in RiskLevel.values) {
        final light = RiskLevelHelper.toTextColor(level, isDark: false);
        final dark = RiskLevelHelper.toTextColor(level, isDark: true);
        expect(light, isNot(equals(dark)),
            reason: '$level should have different text colors for light/dark');
      }
    });
  });

  group('RiskLevelHelper.toLabelKey', () {
    test('low returns result_low_risk', () {
      expect(RiskLevelHelper.toLabelKey(RiskLevel.low), 'result_low_risk');
    });

    test('medium returns result_medium_risk', () {
      expect(RiskLevelHelper.toLabelKey(RiskLevel.medium), 'result_medium_risk');
    });

    test('high returns result_high_risk', () {
      expect(RiskLevelHelper.toLabelKey(RiskLevel.high), 'result_high_risk');
    });
  });

  group('RiskLevelHelper.toIcon', () {
    test('low returns info_rounded', () {
      expect(RiskLevelHelper.toIcon(RiskLevel.low), Icons.info_rounded);
    });

    test('medium returns warning_rounded', () {
      expect(RiskLevelHelper.toIcon(RiskLevel.medium), Icons.warning_rounded);
    });

    test('high returns warning_amber_rounded', () {
      expect(RiskLevelHelper.toIcon(RiskLevel.high), Icons.warning_amber_rounded);
    });
  });
}
