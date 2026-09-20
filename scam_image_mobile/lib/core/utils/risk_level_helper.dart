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
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
      case RiskLevel.unknown:
        return AppColors.outline;
    }
  }

  /// Background tint for the risk badge pill.
  static Color toBgColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.low:
        return AppColors.success.withValues(alpha: isDark ? 0.22 : 0.12);
      case RiskLevel.medium:
        return AppColors.warning.withValues(alpha: isDark ? 0.22 : 0.12);
      case RiskLevel.high:
        return AppColors.danger.withValues(alpha: isDark ? 0.22 : 0.10);
      case RiskLevel.unknown:
        return AppColors.outline.withValues(alpha: isDark ? 0.22 : 0.10);
    }
  }

  /// Text / icon color on top of the badge background.
  static Color toTextColor(RiskLevel level, {required bool isDark}) {
    switch (level) {
      case RiskLevel.low:
        return isDark ? AppColors.successDark : AppColors.success;
      case RiskLevel.medium:
        return isDark ? AppColors.warningDark : AppColors.warning;
      case RiskLevel.high:
        return isDark ? AppColors.dangerDark : AppColors.danger;
      case RiskLevel.unknown:
        return isDark ? AppColors.outlineVariant : AppColors.outline;
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
