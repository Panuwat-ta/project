import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  String? _fetchedName;
  String? _fetchedAvatar;
  bool _fetchingUser = false;
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRealUser());
  }

  Future<void> _ensureRealUser() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return;
    if (_fetchingUser || _didFetch) return;
    setState(() => _fetchingUser = true);
    try {
      final user = await ServiceLocator.authRepository.getCurrentUser();
      if (!mounted || user == null) return;
      // Feed the real user back into the app-scoped AuthBloc so every
      // watcher (settings, profile) flips from placeholder to real data.
      context.read<AuthBloc>().add(AuthSessionRestored(user));
      setState(() {
        _fetchedName = user.displayName.isNotEmpty ? user.displayName : user.email;
        _fetchedAvatar = user.avatarUrl;
      });
    } catch (_) {
      // No valid session / network unavailable — keep placeholder.
    } finally {
      if (mounted) {
        setState(() {
          _fetchingUser = false;
          _didFetch = true;
        });
      }
    }
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'clear_cache_title'.tr(context),
          style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        content: Text(
          'clear_cache_desc'.tr(context),
          style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                Text('clear_cache'.tr(context), style: TextStyle(color: isDark ? Colors.white : AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // Actually delete cached files, then refresh the shown size.
      await context.read<SettingsCubit>().clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('confirm_clear_cache'.tr(context))),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'logout_title'.tr(context),
          style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        content: Text(
          'logout_desc'.tr(context),
          style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'logout'.tr(context),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // Clear the real session (server logout + local tokens).
      context.read<AuthBloc>().add(const LogoutRequested());
      context.go('/login');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = context.read<SettingsCubit>().state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('select_language'.tr(context), style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('language_th'.tr(context), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentLanguage == 'th' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setLanguage('th');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('language_en'.tr(context), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentLanguage == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final currentMode = context.read<SettingsCubit>().state.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('select_theme'.tr(context), style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('theme_light'.tr(context), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentMode == ThemeMode.light ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                context.read<SettingsCubit>().setTheme(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('theme_dark'.tr(context), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              trailing: currentMode == ThemeMode.dark ? const Icon(Icons.check, color: AppColors.primary) : null,
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, units.length - 1);
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(size >= 100 || i == 0 ? 0 : 1)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    // Keep listening so the header updates the instant the restored
    // user lands in AuthBloc (splash or _ensureRealUser).
    final authState = context.watch<AuthBloc>().state;
    // If still unauthenticated on this frame, kick off the fallback fetch.
    if (authState is! AuthAuthenticated && !_didFetch && !_fetchingUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRealUser());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    String userName = _fetchedName ?? 'ผู้ใช้งาน';
    String? avatarUrl = _fetchedAvatar;
    bool showUserLoading = _fetchingUser && authState is! AuthAuthenticated;
    if (authState is AuthAuthenticated) {
      if (authState.user.displayName.isNotEmpty) {
        userName = authState.user.displayName;
      } else if (authState.user.email.isNotEmpty) {
        // Fall back to email prefix when displayName is empty.
        userName = authState.user.email.split('@').first;
      }
      avatarUrl = authState.user.avatarUrl ?? _fetchedAvatar;
      showUserLoading = false;
    } else if (_fetchingUser) {
      userName = 'กำลังโหลด...';
    }

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
            onPressed: () => context.push('/notifications'),
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
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey[400]) : null,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showUserLoading) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'basic_protection'.tr(context)} • v1.0.0',
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

          // ── Account Settings ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'settings_category_account'.tr(context),
              style: AppTypography.caption(color: isDark ? Colors.white54 : AppColors.textSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF1B222C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsListItem(
                  icon: Icons.person_outline,
                  title: 'account'.tr(context),
                  onTap: () => context.go('/main/settings/profile'),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                _SettingsListItem(
                  icon: Icons.notifications_none,
                  title: 'notifications'.tr(context),
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── App Preferences ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'settings_category_preferences'.tr(context),
              style: AppTypography.caption(color: isDark ? Colors.white54 : AppColors.textSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF1B222C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    final languageText = state.language == 'th' ? 'ไทย' : 'English';
                    return _SettingsListItem(
                      icon: Icons.language_outlined,
                      title: 'language'.tr(context),
                      trailingText: languageText,
                      onTap: () => _showLanguageDialog(context),
                    );
                  },
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    final themeText = state.themeMode == ThemeMode.dark
                        ? 'theme_dark'.tr(context)
                        : 'theme_light'.tr(context);
                    return _SettingsListItem(
                      icon: Icons.palette_outlined,
                      title: 'theme'.tr(context),
                      trailingText: themeText,
                      onTap: () => _showThemeDialog(context),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Data & Privacy ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'settings_category_data_privacy'.tr(context),
              style: AppTypography.caption(color: isDark ? Colors.white54 : AppColors.textSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF1B222C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsListItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'privacy'.tr(context),
                  onTap: () => context.go('/main/settings/privacy'),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    return _SettingsListItem(
                      icon: Icons.delete_outline,
                      title: 'clear_cache'.tr(context),
                      trailingText: _formatBytes(state.cacheSizeBytes),
                      showSpinner: state.isClearingCache,
                      onTap: () => _confirmClearCache(context),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Logout Button ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: Text('logout'.tr(context), style: const TextStyle(color: AppColors.danger, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.danger),
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
    this.showSpinner = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final bool showSpinner;
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
          if (showSpinner)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (trailingText != null)
            Text(
              trailingText!,
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 14),
            ),
          if (trailingText != null || showSpinner) const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
        ],
      ),
      onTap: onTap,
    );
  }
}
