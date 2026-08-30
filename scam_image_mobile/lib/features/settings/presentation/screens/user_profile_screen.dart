import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final authState = context.watch<AuthBloc>().state;
    String userName = 'panuwat takham';
    String userEmail = 'panuwat@gmail.com';
    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName;
      userEmail = authState.user.email;
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
                          backgroundImage: const AssetImage('assets/images/profile.jpg'),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('coming_soon'.tr(context))),
                      );
                    },
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
                      onTap: () {},
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      title: 'profile_email'.tr(context),
                      value: userEmail,
                      onTap: () {},
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      icon: Icons.lock_outline,
                      title: 'profile_change_password'.tr(context),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Delete Account Button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cancel_presentation, color: AppColors.danger),
                label: Text('profile_delete_account'.tr(context), style: const TextStyle(color: AppColors.danger, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.danger),
                  backgroundColor: isDark ? Colors.transparent : Colors.white,
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
                    'ScamGuard v2.4.0',
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
