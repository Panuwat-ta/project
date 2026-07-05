import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';


/// Full-width primary ElevatedButton with optional loading state.
///
/// Uses [AppColors.primaryFixedDim] on dark backgrounds and [AppColors.primary]
/// on light backgrounds via the ambient [Theme].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.leadingIcon,
  });

  final String label;

  /// Null [onPressed] will also disable the button.
  final VoidCallback? onPressed;

  /// When true, replaces the label with a [CircularProgressIndicator].
  final bool isLoading;

  /// Explicit enabled flag — useful when [onPressed] is non-null but the
  /// button should still be locked (e.g. form not yet valid).
  final bool enabled;

  /// Optional icon shown before the label.
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fgColor = isDark ? AppColors.bgDark : AppColors.onPrimary;
    final bool isDisabled = !enabled || onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
