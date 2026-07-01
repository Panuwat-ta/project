import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'risk_badge.dart';

/// Horizontal progress bar (score / 100) with risk-level color fill.
///
/// Height is 6 px, fully rounded caps. The percentage value is shown to
/// the right of the bar.
class RiskProgressBar extends StatelessWidget {
  const RiskProgressBar({
    super.key,
    required this.score,
    this.showLabel = true,
    this.height = 6.0,
  }) : assert(score >= 0 && score <= 100);

  /// 0 – 100 risk score.
  final int score;

  /// Whether to show the "XX%" label beside the bar.
  final bool showLabel;

  /// Bar height in logical pixels (default 6).
  final double height;

  static Color _colorForScore(int score) {
    final level = _levelForScore(score);
    switch (level) {
      case RiskLevel.low:
      case RiskLevel.safe:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  static RiskLevel _levelForScore(int score) {
    if (score < 40) return RiskLevel.low;
    if (score < 70) return RiskLevel.medium;
    return RiskLevel.high;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForScore(score);
    final progress = score / 100.0;
    final trackColor = AppColors.inverseSurface;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: height,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: height,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            '$score%',
            style: AppTypography.codeData(color: color),
          ),
        ],
      ],
    );
  }
}
