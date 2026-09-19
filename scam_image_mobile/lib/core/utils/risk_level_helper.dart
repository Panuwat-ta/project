import 'package:flutter/material.dart';

import '../../features/result/domain/entities/analysis_result.dart';
import '../theme/app_colors.dart';

/// Presentation mappers for a [RiskLevel] (3 ระดับ + unknown).
///
/// The overall grade is owned by the server RiskScore module — mobile never
/// recomputes it. [factorLevelForScore] is presentation-only for per-factor
/// pills and must not be used as the overall grade.
class RiskLevelHelper {
  RiskLevelHelper._();

  /// Presentation-only mapping of a single factor score to a level pill.
  /// Not a grade authority: the overall grade always comes from the server.
  static RiskLevel factorLevelForScore(int score) {
    if (score >= 70) return RiskLevel.high;
    if (score >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static String toThaiLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.unknown:
        return 'Unknown';
    }
  }

  /// Primary color for the given risk level.
  static Color toColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppColors.tertiary;
      case RiskLevel.medium:
        return const Color(0xFFEA580C); // orange-600
      case RiskLevel.high:
        return AppColors.danger;
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }

  /// Background tint for the risk badge pill.
  static Color toBgColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.low:
        return isDark ? const Color(0xFF332B14) : const Color(0xFFFEF9C3);
      case RiskLevel.medium:
        return isDark ? const Color(0xFF33200E) : const Color(0xFFFFF7ED);
      case RiskLevel.high:
        return isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB);
      case RiskLevel.unknown:
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    }
  }

  /// Text / icon color on top of the badge background.
  static Color toTextColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.low:
        return isDark ? const Color(0xFFFDE68A) : AppColors.tertiary;
      case RiskLevel.medium:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
      case RiskLevel.high:
        return isDark ? const Color(0xFFFFB4B4) : AppColors.danger;
      case RiskLevel.unknown:
        return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
    }
  }

  /// Localization key for the risk level label.
  static String toLabelKey(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'result_low_risk';
      case RiskLevel.medium:
        return 'result_medium_risk';
      case RiskLevel.high:
        return 'result_high_risk';
      case RiskLevel.unknown:
        return 'result_unknown_risk';
    }
  }

  /// Icon for the risk level.
  static IconData toIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Icons.info_rounded;
      case RiskLevel.medium:
        return Icons.warning_rounded;
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.unknown:
        return Icons.help_outline_rounded;
    }
  }
}
