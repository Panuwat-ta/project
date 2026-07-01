import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Custom top bar implementing [PreferredSizeWidget].
///
/// Shows a shield-lock icon + "ScamGuard" title. Accepts optional [actions].
/// Preferred height is 64 px. The bottom has a 1 px divider using
/// [AppColors.outlineVariant].
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? AppColors.primaryFixedDim : AppColors.primary;

    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            color: titleColor,
            size: 24,
            semanticLabel: 'ScamGuard shield icon',
          ),
          const SizedBox(width: 8),
          Text(
            'ScamGuard',
            style: AppTypography.sectionHeader(color: titleColor),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
