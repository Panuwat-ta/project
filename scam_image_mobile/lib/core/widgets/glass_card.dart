import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Semi-transparent "glass" card for dark mode UI.
///
/// Background: [AppColors.surfaceDark] at 80% opacity.
/// Border: [AppColors.outlineVariant] at 10% opacity.
/// Border radius: 12 dp.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;

  /// Inner padding (defaults to 20 dp on all sides).
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
