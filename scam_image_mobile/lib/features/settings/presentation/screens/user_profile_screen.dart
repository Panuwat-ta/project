import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141921) : const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1B222C) : Colors.white,
        leading: const BackButton(),
        centerTitle: true,
        title: Text(
          'โปรไฟล์',
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
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
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
                    'panuwat takham',
                    style: AppTypography.headlineLgMobile(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'panuwat@gmail.com',
                    style: AppTypography.bodyBase(color: isDark ? Colors.white54 : AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'แก้ไขโปรไฟล์',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้')),
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
                      title: 'ชื่อ-นามสกุล',
                      value: 'panuwat takham',
                      onTap: () {},
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      title: 'อีเมล',
                      value: 'panuwat@gmail.com',
                      onTap: () {},
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    _ProfileListItem(
                      icon: Icons.lock_outline,
                      title: 'เปลี่ยนรหัสผ่าน',
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
                label: const Text('ลบบัญชีผู้ใช้งาน', style: TextStyle(color: AppColors.danger, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
