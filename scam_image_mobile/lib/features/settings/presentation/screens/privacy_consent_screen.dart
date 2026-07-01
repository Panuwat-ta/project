import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../bloc/settings_bloc.dart';

/// Privacy & Consent management screen.
///
/// Allows toggling data-use consents, requesting a data export,
/// and permanently deleting the user's account.
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  late final SettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SettingsCubit(repository: MockSettingsRepository());
    _cubit.loadConsents();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ── Export ──────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    await _cubit.exportData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังดำเนินการส่งสำเนาข้อมูลของคุณ')),
      );
    }
  }

  // ── Delete account ──────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    // Step 1: first confirm dialog
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'ลบบัญชี',
          style: AppTypography.titleMd(color: Colors.white),
        ),
        content: Text(
          'การลบบัญชีจะลบข้อมูลทั้งหมดของคุณออกจากระบบอย่างถาวร '
          'คุณต้องการดำเนินการต่อหรือไม่?',
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
              'ดำเนินการต่อ',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Step 2: final confirmation
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'ยืนยันการลบบัญชี',
          style: AppTypography.titleMd(color: AppColors.danger),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
          style: AppTypography.bodyBase(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ไม่ใช่'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบบัญชีของฉัน'),
          ),
        ],
      ),
    );
    if (step2 != true || !mounted) return;

    await _cubit.deleteAccount();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: Text(
            'ความเป็นส่วนตัว',
            style: AppTypography.headlineLgMobile(color: Colors.white),
          ),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryFixedDim,
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                // ── Consent Management ─────────────────────────────────
                _SectionHeader(label: 'การจัดการความยินยอม'),
                const SizedBox(height: AppSpacing.sm),

                _ConsentTile(
                  title: 'ประมวลผลรูปภาพ',
                  subtitle: 'ยินยอมให้ประมวลผลรูปภาพที่อัปโหลด (จำเป็น)',
                  value: state.consent.processingConsent,
                  onChanged: null, // required — always on
                ),
                const SizedBox(height: AppSpacing.xs),

                _ConsentTile(
                  title: 'เก็บประวัติการสแกน',
                  subtitle: 'บันทึกผลการวิเคราะห์ไว้ในประวัติของคุณ',
                  value: state.consent.historyConsent,
                  onChanged: (val) {
                    final updated = state.consent.copyWith(historyConsent: val);
                    context.read<SettingsCubit>().updateConsents(updated);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                _ConsentTile(
                  title: 'ใช้เพื่อปรับปรุงโมเดล AI',
                  subtitle:
                      'อนุญาตให้ใช้ข้อมูลแบบไม่ระบุตัวตนเพื่อปรับปรุงโมเดล',
                  value: state.consent.researchConsent,
                  onChanged: (val) {
                    final updated =
                        state.consent.copyWith(researchConsent: val);
                    context.read<SettingsCubit>().updateConsents(updated);
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Personal Data ──────────────────────────────────────
                _SectionHeader(label: 'ข้อมูลส่วนตัว'),
                const SizedBox(height: AppSpacing.sm),

                // Export data
                OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('ขอรับสำเนาข้อมูล'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryFixedDim,
                    side: const BorderSide(color: AppColors.primaryFixedDim),
                    minimumSize: const Size(double.infinity, 52),
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Delete account
                ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('ลบบัญชี'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 4),
      child: Text(
        label,
        style: AppTypography.sectionHeader(color: Colors.white),
      ),
    );
  }
}

// ── Consent tile ──────────────────────────────────────────────────────────────

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryFixedDim,
        title: Text(
          title,
          style: AppTypography.bodyBase(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption(color: Colors.white54),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
