import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Risk level values accepted by [RiskBadge].
enum RiskLevel { low, medium, high, safe }

/// Small pill-shaped badge that communicates a risk level with color + Thai text.
///
/// * low    → success green  / ต่ำ
/// * medium → warning amber  / ปานกลาง
/// * high   → danger red     / สูง
/// * safe   → success green  / ปลอดภัย
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  static _BadgeStyle _styleFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return _BadgeStyle(
          bg: AppColors.success,
          fg: Colors.white,
          label: 'ต่ำ',
        );
      case RiskLevel.medium:
        return _BadgeStyle(
          bg: AppColors.warning,
          fg: Colors.white,
          label: 'ปานกลาง',
        );
      case RiskLevel.high:
        return _BadgeStyle(
          bg: AppColors.danger,
          fg: Colors.white,
          label: 'สูง',
        );
      case RiskLevel.safe:
        return _BadgeStyle(
          bg: AppColors.success,
          fg: Colors.white,
          label: 'ปลอดภัย',
        );
    }
  }

  /// Convenience constructor from a string value.
  static RiskLevel levelFromString(String value) {
    switch (value.toLowerCase()) {
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'safe':
        return RiskLevel.safe;
      case 'low':
      default:
        return RiskLevel.low;
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
        style: AppTypography.caption(color: style.fg).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.bg,
    required this.fg,
    required this.label,
  });
  final Color bg;
  final Color fg;
  final String label;
}
