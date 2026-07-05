import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../localization/app_translations.dart';

/// 4-tab bottom navigation bar.
///
/// Tabs (in order):
/// 0 – หน้าหลัก  (home)
/// 1 – ประวัติ    (history)
/// 2 – แจ้งรายงาน (flag)
/// 3 – ตั้งค่า    (settings)
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor =
        isDark ? AppColors.primaryFixedDim : AppColors.primary;
    final Color inactiveColor = AppColors.textSecondary;
    final Color bgColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: bgColor,
      selectedItemColor: activeColor,
      unselectedItemColor: inactiveColor,
      iconSize: 22,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: AppTypography.caption(color: activeColor).copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: AppTypography.caption(color: inactiveColor).copyWith(
        fontSize: 11,
      ),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'home'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: const Icon(Icons.history),
          label: 'history'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.flag_outlined),
          activeIcon: const Icon(Icons.flag),
          label: 'report'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: 'settings'.tr(context),
        ),
      ],
    );
  }
}
