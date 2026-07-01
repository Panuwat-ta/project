import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/consent_cubit.dart';

/// Onboarding & consent screen shown to first-time users.
///
/// Creates a [ConsentCubit] inline. Real persistence of consent state
/// will be wired in Task 23.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConsentCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.safeMargin,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Shield icon ───────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryFixedDim.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 48,
                  color: AppColors.primaryFixedDim,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── App title ─────────────────────────────────────────────────
              Text(
                'ScamGuard',
                style: AppTypography.headlineLgMobile(color: Colors.white),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Description ───────────────────────────────────────────────
              Text(
                'แอปพลิเคชันตรวจสอบรูปภาพต้องสงสัย ช่วยคุณวิเคราะห์และประเมินความเสี่ยง'
                'ของรูปภาพก่อนตัดสินใจ ปกป้องคุณจากภัยหลอกลวงออนไลน์',
                style: AppTypography.bodyBase(color: AppColors.outlineVariant),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Disclaimer ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'ผลการประเมินเป็นเพียงการประเมินความเสี่ยง '
                        'ไม่ใช่คำตัดสินทางกฎหมาย',
                        style: AppTypography.caption(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Consent checkboxes ────────────────────────────────────────
              BlocBuilder<ConsentCubit, ConsentState>(
                builder: (context, state) {
                  final cubit = context.read<ConsentCubit>();
                  return Column(
                    children: [
                      ConsentCheckboxTile(
                        value: state.termsAccepted,
                        onChanged: (_) => cubit.toggleTerms(),
                        label: 'ฉันยอมรับเงื่อนไขการใช้งาน',
                        description: 'จำเป็นต้องยอมรับเพื่อใช้งานแอป',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ConsentCheckboxTile(
                        value: state.researchConsent,
                        onChanged: (_) => cubit.toggleResearch(),
                        label: 'ยินยอมให้นำข้อมูลไปปรับปรุงโมเดล AI',
                        description: 'ไม่บังคับ — ช่วยพัฒนาระบบให้ดียิ่งขึ้น',
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Proceed button ────────────────────────────────────
                      PrimaryButton(
                        label: 'ดำเนินการต่อ',
                        enabled: state.canProceed,
                        onPressed:
                            state.canProceed ? () => context.go('/login') : null,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
