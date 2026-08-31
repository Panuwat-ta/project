import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../bloc/settings_bloc.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {

  Future<void> _exportData() async {
    await context.read<SettingsCubit>().exportData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('privacy_exporting'.tr(context))),
      );
    }
  }

  Future<void> _deleteAllData() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'privacy_delete_title'.tr(context),
          style: AppTypography.titleMd(color: AppColors.danger),
        ),
        content: Text(
          'privacy_delete_desc'.tr(context),
          style: AppTypography.bodyBase(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete_data'.tr(context)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('privacy_deleted'.tr(context))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141921) : const Color(0xFFF5F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1B222C) : Colors.white,
          leading: const BackButton(),
          title: Text(
            'privacy_title'.tr(context),
            style: TextStyle(
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: isDark ? Colors.white : AppColors.textPrimary),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              children: [
                // ── Header Icon and Titles ─────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B222C) : const Color(0xFFDFF1FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.security, size: 40, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'privacy_manage_consent'.tr(context),
                        style: AppTypography.headlineLgMobile(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'privacy_manage_desc'.tr(context),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyBase(color: isDark ? Colors.white54 : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Consent List Container ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B222C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _ConsentTile(
                        title: 'privacy_consent_process_title'.tr(context),
                        subtitle: 'privacy_consent_process_desc'.tr(context),
                        value: state.consent.processingConsent,
                        onChanged: null, 
                      ),
                      Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                      _ConsentTile(
                        title: 'privacy_consent_history_title'.tr(context),
                        subtitle: 'privacy_consent_history_desc'.tr(context),
                        value: state.consent.historyConsent,
                        onChanged: (val) {
                          final updated = state.consent.copyWith(historyConsent: val);
                          context.read<SettingsCubit>().updateConsents(updated);
                        },
                      ),
                      Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                      _ConsentTile(
                        title: 'privacy_consent_ai_title'.tr(context),
                        subtitle: 'privacy_consent_ai_desc'.tr(context),
                        value: state.consent.researchConsent,
                        onChanged: (val) {
                          final updated = state.consent.copyWith(researchConsent: val);
                          context.read<SettingsCubit>().updateConsents(updated);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Action Buttons ────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_outlined),
                  label: Text('privacy_export_data'.tr(context), style: const TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                    side: BorderSide(color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.cancel_presentation, color: AppColors.danger),
                  label: Text('privacy_delete_all_data'.tr(context), style: const TextStyle(color: AppColors.danger, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Info Box ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A3441) : const Color(0xFFEAF5FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'privacy_info_desc'.tr(context),
                          style: AppTypography.caption(color: isDark ? Colors.white70 : AppColors.textSecondary).copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),

                // ── Bottom Shield Watermark ──────────────────────────────
                Opacity(
                  opacity: 0.05,
                  child: Center(
                    child: Icon(Icons.security, size: 200, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            );
          },
        ),
      );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[400],
        title: Text(
          title,
          style: AppTypography.bodyBase(color: isDark ? Colors.white : AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: AppTypography.caption(color: isDark ? Colors.white54 : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
