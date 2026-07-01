import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

/// Displays and allows editing of the authenticated user's profile.
///
/// Real save functionality (API call) will be wired in Task 23.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController(text: 'ผู้ใช้งาน');
  final _emailController =
      TextEditingController(text: 'user@example.com');

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'โปรไฟล์ผู้ใช้',
          style: AppTypography.headlineLgMobile(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeMargin,
          vertical: AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar ─────────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.surfaceDark,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 44,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixedDim,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bgDark,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.bgDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Display Name field ─────────────────────────────────────
              _FieldLabel(label: 'ชื่อที่แสดง'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _displayNameController,
                style: AppTypography.bodyBase(color: Colors.white),
                decoration: _inputDecoration('กรอกชื่อที่แสดง'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Email field (read-only) ────────────────────────────────
              _FieldLabel(label: 'อีเมล'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: AppTypography.bodyBase(color: Colors.white54),
                decoration: _inputDecoration('อีเมล').copyWith(
                  suffixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Save button ────────────────────────────────────────────
              PrimaryButton(
                label: 'บันทึก',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyBase(color: Colors.white30),
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.gutter,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryFixedDim),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      );
}

// ── Field label helper ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTypography.caption(color: AppColors.primaryFixedDim),
      ),
    );
  }
}
