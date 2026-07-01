import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Semicircle (bottom half) gauge rendered via [CustomPainter].
///
/// The arc sweeps from the left end to the right end (180° total).
/// Track color: [AppColors.inverseSurface].
/// Fill color: risk-level color derived from [score].
class RiskGauge extends StatelessWidget {
  const RiskGauge({
    super.key,
    required this.score,
    this.size = 200.0,
    this.strokeWidth = 14.0,
  }) : assert(score >= 0 && score <= 100);

  /// 0 – 100.
  final int score;

  /// Width / height of the bounding box.
  final double size;

  /// Arc stroke width.
  final double strokeWidth;

  static Color _colorForScore(int score) {
    if (score < 40) return AppColors.success;
    if (score < 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _colorForScore(score);
    // The widget is a half-circle so natural height = size / 2 + extra for label
    final gaugeHeight = size / 2 + strokeWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: gaugeHeight,
          child: CustomPaint(
            painter: _GaugePainter(
              progress: score / 100.0,
              trackColor: AppColors.inverseSurface,
              fillColor: fillColor,
              strokeWidth: strokeWidth,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: AppTypography.headlineLgMobile(color: fillColor).copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Full track: from 180° (left) to 360°/0° (right) — i.e. bottom semicircle
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Fill arc proportional to progress
    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
