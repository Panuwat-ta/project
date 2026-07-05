import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';

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

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
