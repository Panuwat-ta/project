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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariant.withValues(alpha: 0.1)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
