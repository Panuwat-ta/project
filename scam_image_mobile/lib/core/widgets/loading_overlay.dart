import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Full-screen (or contained) semi-transparent overlay with a spinner.
///
/// Wrap a [Stack] or use [Stack] + conditional render to overlay content.
/// When [message] is provided it is shown below the spinner.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
    this.isFullScreen = true,
  });

  /// Optional descriptive text shown below the [CircularProgressIndicator].
  final String? message;

  /// When true the overlay fills the entire screen. Set to false for
  /// contained usage inside a smaller widget.
  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color spinnerColor =
        isDark ? AppColors.primaryFixedDim : AppColors.primary;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodyBase(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (!isFullScreen) return content;

    return Container(
      color: AppColors.bgDark.withValues(alpha: 0.7),
      child: content,
    );
  }
}
