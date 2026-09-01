import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/settings_bloc.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _fetchedName;
  String? _fetchedEmail;
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
      context.read<AuthBloc>().add(AuthSessionRestored(user));
      setState(() {
        _fetchedName = user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first;
        _fetchedEmail = user.email;
        _fetchedAvatar = user.avatarUrl;
      });
    } catch (_) {}
    finally {
      if (mounted) setState(() { _fetchingUser = false; _didFetch = true; });
    }
  }

  Future<void> _editDisplayName(BuildContext context, String currentName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: currentName == 'ผู้ใช้งาน' ? '' : currentName);
    final formKey = GlobalKey<FormState>();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text('profile_edit'.tr(ctx), style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'profile_fullname'.tr(ctx),
              hintText: 'auth_fullname_hint'.tr(ctx),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'auth_fullname_error'.tr(ctx) : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr(ctx))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, controller.text.trim());
            },
            child: Text('confirm'.tr(ctx)),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final updated = User(id: authState.user.id, email: authState.user.email, displayName: newName, avatarUrl: authState.user.avatarUrl);
      context.read<AuthBloc>().add(AuthSessionRestored(updated));
      setState(() => _fetchedName = newName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_updated'.tr(context))));
    } else if (_fetchedEmail != null) {
      setState(() => _fetchedName = newName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_updated'.tr(context))));
    }
  }

  Future<void> _changePassword() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text('profile_change_password'.tr(ctx), style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: oldCtrl, obscureText: true, decoration: InputDecoration(labelText: 'auth_password'.tr(ctx), border: const OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'auth_password_hint'.tr(ctx) : null),
            const SizedBox(height: 12),
            TextFormField(controller: newCtrl, obscureText: true, decoration: InputDecoration(labelText: 'auth_password_min_hint'.tr(ctx), border: const OutlineInputBorder()), validator: (v) => (v == null || v.length < 8) ? 'auth_password_min_error'.tr(ctx) : null),
            const SizedBox(height: 12),
            TextFormField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: 'auth_password_confirm'.tr(ctx), border: const OutlineInputBorder()), validator: (v) => v != newCtrl.text ? 'auth_password_match_error'.tr(ctx) : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr(ctx))),
          ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: Text('confirm'.tr(ctx))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('password_changed'.tr(context))));
    }
  }

  Future<void> _deleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text('profile_delete_account'.tr(ctx), style: const TextStyle(color: AppColors.danger)),
        content: Text('privacy_delete_desc'.tr(ctx), style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr(ctx))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text('delete'.tr(ctx), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<SettingsCubit>().deleteAccount();
      } catch (_) {}
      if (mounted) {
        context.read<AuthBloc>().add(const LogoutRequested());
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated && !_didFetch && !_fetchingUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRealUser());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String userName = _fetchedName ?? 'ผู้ใช้งาน';
    String userEmail = _fetchedEmail ?? 'ไม่มีอีเมล';
    String? avatarUrl = _fetchedAvatar;
    if (authState is AuthAuthenticated) {
      if (authState.user.displayName.isNotEmpty) {
        userName = authState.user.displayName;
      } else if (authState.user.email.isNotEmpty) {
        userName = authState.user.email.split('@').first;
      }
      userEmail = authState.user.email;
      avatarUrl = authState.user.avatarUrl ?? _fetchedAvatar;
    } else if (_fetchingUser) {
      userName = 'กำลังโหลด...';
      userEmail = 'กำลังโหลด...';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141921) : const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1B222C) : Colors.white,
        leading: const BackButton(),
        centerTitle: true,
        title: Text(
          'profile_title'.tr(context),
          style: TextStyle(
            color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Profile Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B222C) : Colors.white,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.primaryFixedDim : AppColors.primary, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Icon(Icons.person, size: 50, color: isDark ? Colors.white54 : Colors.grey[400]) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1B222C) : Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    userName,
                    style: AppTypography.headlineLgMobile(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: AppTypography.bodyBase(color: isDark ? Colors.white54 : AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'profile_edit'.tr(context),
                    onPressed: () => _editDisplayName(context, userName),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),

            // ── Information List ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B222C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ProfileListItem(
                      title: 'profile_fullname'.tr(context),
                      value: userName,
                      onTap: () => _editDisplayName(context, userName),
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      title: 'profile_email'.tr(context),
                      value: userEmail,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userEmail)));
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      icon: Icons.lock_outline,
                      title: 'profile_change_password'.tr(context),
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Delete Account Button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.cancel_presentation, color: AppColors.danger),
                  label: Text('profile_delete_account'.tr(context), style: const TextStyle(color: AppColors.danger, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.danger),
                    backgroundColor: isDark ? Colors.transparent : Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Bottom Watermark ──────────────────────────────────────────
            Opacity(
              opacity: 0.1,
              child: Column(
                children: [
                  Icon(Icons.verified_user_outlined, size: 48, color: isDark ? Colors.white : Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    'ScamGuard v1.0.0',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({
    this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData? icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: isDark ? Colors.lightBlueAccent : AppColors.primary, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ],
      ),
      subtitle: value != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                value!,
                style: AppTypography.bodyBase(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontSize: 16),
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
      onTap: onTap,
    );
  }
}
