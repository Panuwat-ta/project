import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Real main shell with themed bottom navigation bar.
///
/// Replaces [MainShellPlaceholder] as part of Task 22/23 integration.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static int _indexFromLocation(String location) {
    if (location.startsWith('/main/history')) return 1;
    if (location.startsWith('/main/report')) return 2;
    if (location.startsWith('/main/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor =
        isDark ? AppColors.primaryFixedDim : AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.outlineVariant : AppColors.textSecondary;
    final bgColor =
        Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? AppColors.outlineVariant.withValues(alpha: 0.3)
        : AppColors.border;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'หน้าหลัก',
                  isActive: currentIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => context.go('/main/home'),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'ประวัติ',
                  isActive: currentIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => context.go('/main/history'),
                ),
                _NavItem(
                  icon: Icons.flag_outlined,
                  activeIcon: Icons.flag,
                  label: 'แจ้งรายงาน',
                  isActive: currentIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => context.go('/main/report'),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'ตั้งค่า',
                  isActive: currentIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => context.go('/main/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
              semanticLabel: label,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption(color: color).copyWith(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
