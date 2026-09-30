import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_typography.dart';
import '../localization/app_translations.dart';

/// Displayed when the user has denied gallery / camera permission.
///
/// Shows an explanatory message and an "เปิดการตั้งค่า" button that
/// opens the device app-settings via [onOpenSettings].
class PermissionRequestView extends StatelessWidget {
  const PermissionRequestView({
    super.key,
    required this.onOpenSettings,
    this.onRetry,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.no_photography_outlined,
          size: 48,
          color: isDark ? AppColors.outlineVariant : AppColors.outline,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'permission_photo_title'.tr(context),
          style: AppTypography.sectionHeader(
            color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'permission_photo_desc'.tr(context),
          style: AppTypography.bodyBase(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(
              'permission_open_settings'.tr(context),
              style: AppTypography.buttonLabel(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.primaryFixedDim
                  : AppColors.primary,
              foregroundColor: isDark ? AppColors.bgDark : AppColors.onPrimary,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'common_retry'.tr(context),
              style: AppTypography.buttonLabel(
                color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
