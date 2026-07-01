import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../bloc/settings_bloc.dart';

/// Main settings screen — lists all user-configurable options.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(repository: MockSettingsRepository()),
      child: const _SettingsView(),
    );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'ล้าง Cache',
          style: AppTypography.titleMd(color: Colors.white),
        ),
        content: Text(
          'คุณต้องการล้าง Cache ของแอปใช่หรือไม่?',
          style: AppTypography.bodyBase(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('ล้าง Cache', style: TextStyle(color: Colors.white)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'ออกจากระบบ',
          style: AppTypography.titleMd(color: Colors.white),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
          style: AppTypography.bodyBase(color: Colors.white70),
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
      // Real token clearing will be wired in Task 23.
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text(
          'ตั้งค่า',
          style: AppTypography.headlineLgMobile(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          // ── User header ────────────────────────────────────────────────
          _UserHeader(),
          const SizedBox(height: AppSpacing.lg),

          // ── General section ────────────────────────────────────────────
          _SectionLabel(label: 'บัญชีผู้ใช้'),
          const SizedBox(height: AppSpacing.xs),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'โปรไฟล์ผู้ใช้',
            onTap: () => context.go('/main/settings/profile'),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'การแจ้งเตือน',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'ภาษา',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Appearance section ─────────────────────────────────────────
          _SectionLabel(label: 'การแสดงผล'),
          const SizedBox(height: AppSpacing.xs),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'รูปแบบธีม',
                trailing: Switch(
                  value: state.themeMode == ThemeMode.light,
                  onChanged: (_) =>
                      context.read<SettingsCubit>().toggleTheme(),
                  activeThumbColor: AppColors.primaryFixedDim,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Privacy section ────────────────────────────────────────────
          _SectionLabel(label: 'ความเป็นส่วนตัว'),
          const SizedBox(height: AppSpacing.xs),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'ความเป็นส่วนตัว',
            onTap: () => context.go('/main/settings/privacy'),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Storage section ────────────────────────────────────────────
          _SectionLabel(label: 'ข้อมูลและหน่วยความจำ'),
          const SizedBox(height: AppSpacing.xs),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'ล้าง Cache',
            onTap: () => _confirmClearCache(context),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Danger zone ────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.logout,
            title: 'ออกจากระบบ',
            iconColor: AppColors.danger,
            titleColor: AppColors.danger,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── User header ───────────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/main/settings/profile'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.bgDark,
              child: const Icon(Icons.person, color: Colors.white54, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ผู้ใช้งาน',
                    style: AppTypography.sectionHeader(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'user@example.com',
                    style: AppTypography.caption(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: AppColors.primaryFixedDim),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ?? AppColors.primaryFixedDim,
          semanticLabel: title,
        ),
        title: Text(
          title,
          style: AppTypography.bodyBase(color: titleColor ?? Colors.white),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: Colors.white38)
                : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
