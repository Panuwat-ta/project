import 'package:flutter/material.dart';
import '../../features/result/domain/entities/analysis_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Small pill-shaped badge that communicates a risk level with color + Thai text.
///
/// * low     → success green  / ต่ำ (0-39%)
/// * medium  → warning amber  / ปานกลาง (40-69%)
/// * high    → danger red     / สูง (70-100%)
/// * unknown → grey           / ไม่ทราบ (grade missing — never Low)
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  static _BadgeStyle _styleFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return _BadgeStyle(
          bg: AppColors.success.withValues(alpha: 0.15),
          fg: AppColors.success,
          label: 'ต่ำ',
        );
      case RiskLevel.medium:
        return _BadgeStyle(
          bg: AppColors.warning.withValues(alpha: 0.15),
          fg: AppColors.warning,
          label: 'ปานกลาง',
        );
      case RiskLevel.high:
        return _BadgeStyle(
          bg: AppColors.danger.withValues(alpha: 0.15),
          fg: AppColors.danger,
          label: 'ความเสี่ยงสูง',
        );
      case RiskLevel.unknown:
        return _BadgeStyle(
          bg: Colors.grey.withValues(alpha: 0.15),
          fg: Colors.grey.shade700,
          label: 'ไม่ทราบ',
        );
    }
  }

  /// Convenience constructor from a string value.
  /// Unknown or missing values map to [RiskLevel.unknown], never Low.
  static RiskLevel levelFromString(String value) {
    switch (value.toLowerCase()) {
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'low':
        return RiskLevel.low;
      default:
        return RiskLevel.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(riskLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        style.label,
        style: AppTypography.caption(
          color: style.fg,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({required this.bg, required this.fg, required this.label});
  final Color bg;
  final Color fg;
  final String label;
}
