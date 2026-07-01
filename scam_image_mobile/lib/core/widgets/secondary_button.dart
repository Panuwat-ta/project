import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Full-width outlined secondary button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !enabled || onPressed == null;
    final Color fgColor = AppColors.primary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          disabledForegroundColor: fgColor.withValues(alpha: 0.4),
          side: BorderSide(
            color: isDisabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.primary,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label, style: AppTypography.buttonLabel(color: fgColor)),
          ],
        ),
      ),
    );
  }
}
