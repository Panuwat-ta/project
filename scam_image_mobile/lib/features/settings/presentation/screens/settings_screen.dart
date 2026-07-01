import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'ล้าง Cache',
          style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        content: Text(
          'คุณต้องการล้าง Cache ของแอปใช่หรือไม่?',
          style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                Text('ล้าง Cache', style: TextStyle(color: isDark ? Colors.white : AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ล้าง Cache สำเร็จ')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'ออกจากระบบ',
          style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
          style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'ออกจากระบบ',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/login');
    }
  }

  void _showThemeDialog(BuildContext context) {
    final currentMode = context.read<SettingsCubit>().state.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('เลือกธีม', style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('ตามระบบ', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentMode == ThemeMode.system ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setTheme(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('สว่าง', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentMode == ThemeMode.light ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setTheme(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('มืด', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentMode == ThemeMode.dark ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setTheme(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141921) : const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1B222C) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'ScamGuard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: isDark ? Colors.white : AppColors.textPrimary),
            onPressed: () => _showComingSoon(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        children: [
          // ── User Header Card ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.go('/main/settings/profile'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B222C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.primaryFixedDim : AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'panuwat takham',
                          style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'การป้องกันระดับพื้นฐาน • v1.0.0',
                          style: AppTypography.caption(color: isDark ? Colors.white54 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Settings List Card ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B222C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingsListItem(
                  icon: Icons.person_outline,
                  title: 'บัญชี',
                  onTap: () => context.go('/main/settings/profile'),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                _SettingsListItem(
                  icon: Icons.notifications_none,
                  title: 'การแจ้งเตือน',
                  onTap: () => _showComingSoon(context),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                _SettingsListItem(
                  icon: Icons.language_outlined,
                  title: 'ภาษา',
                  trailingText: 'ไทย',
                  onTap: () => _showComingSoon(context),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    final themeText = state.themeMode == ThemeMode.system
                        ? 'ตามระบบ'
                        : (state.themeMode == ThemeMode.light ? 'สว่าง' : 'มืด');
                    return _SettingsListItem(
                      icon: Icons.palette_outlined,
                      title: 'ธีม',
                      trailingText: themeText,
                      onTap: () => _showThemeDialog(context),
                    );
                  },
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                _SettingsListItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'ความเป็นส่วนตัว',
                  onTap: () => context.go('/main/settings/privacy'),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                _SettingsListItem(
                  icon: Icons.delete_outline,
                  title: 'ล้างแคช',
                  trailingText: '12.4 MB',
                  onTap: () => _confirmClearCache(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Logout Button ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('ออกจากระบบ', style: TextStyle(color: AppColors.danger, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: isDark ? Colors.transparent : Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3441) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyBase(color: isDark ? Colors.white : AppColors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
        ],
      ),
      onTap: onTap,
    );
  }
}
