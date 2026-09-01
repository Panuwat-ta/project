import 'package:flutter/material.dart';

import '../../features/result/domain/entities/analysis_result.dart';
import '../theme/app_colors.dart';

/// Converts a numeric risk score (0-100) to a [RiskLevel].
///
///
/// 0-19  → safe
/// 20-39 → low
/// 40-69 → medium
/// 70-100 → high
class RiskLevelHelper {
  RiskLevelHelper._();

  static RiskLevel fromScore(int score) {
    if (score < 20) return RiskLevel.safe;
    if (score < 40) return RiskLevel.low;
    if (score < 70) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static String toThaiLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  /// Primary color for the given risk level.
  static Color toColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return AppColors.success;
      case RiskLevel.low:
        return AppColors.tertiary;
      case RiskLevel.medium:
        return const Color(0xFFEA580C); // orange-600
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  /// Background tint for the risk badge pill.
  static Color toBgColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.safe:
        return isDark ? const Color(0xFF14332A) : const Color(0xFFDCFCE7);
      case RiskLevel.low:
        return isDark ? const Color(0xFF332B14) : const Color(0xFFFEF9C3);
      case RiskLevel.medium:
        return isDark ? const Color(0xFF33200E) : const Color(0xFFFFF7ED);
      case RiskLevel.high:
        return isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB);
    }
  }

  /// Text / icon color on top of the badge background.
  static Color toTextColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.safe:
        return isDark ? const Color(0xFF86EFAC) : AppColors.success;
      case RiskLevel.low:
        return isDark ? const Color(0xFFFDE68A) : AppColors.tertiary;
      case RiskLevel.medium:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
      case RiskLevel.high:
        return isDark ? const Color(0xFFFFB4B4) : AppColors.danger;
    }
  }

  /// Localization key for the risk level label.
  static String toLabelKey(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'result_safe';
      case RiskLevel.low:
        return 'result_low_risk';
      case RiskLevel.medium:
        return 'result_medium_risk';
      case RiskLevel.high:
        return 'result_high_risk';
    }
  }

  /// Icon for the risk level.
  static IconData toIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Icons.check_circle_rounded;
      case RiskLevel.low:
        return Icons.info_rounded;
      case RiskLevel.medium:
        return Icons.warning_rounded;
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
    }
  }
}
