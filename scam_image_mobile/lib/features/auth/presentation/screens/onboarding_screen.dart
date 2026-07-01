import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/consent_cubit.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141F2B) : const Color(0xFFF5F7F9);
    final sheetColor = isDark ? const Color(0xFF1E2936) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final primaryColor = const Color(0xFF007293);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Top App Bar/Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2936) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shield, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'ScamGuard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hero Image Section
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/onboarding_hero.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    // Fallback visual if image fails
                    child: Center(
                      child: Icon(Icons.security, size: 100, color: primaryColor.withOpacity(0.5)),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.white, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ตรวจสอบความปลอดภัย',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Bottom Sheet Section
            Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ตรวจสอบรูปภาพเพื่อความปลอดภัย',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'แอปพลิเคชันนี้ถูกออกแบบมาเพื่อช่วยประเมินความเสี่ยงเบื้องต้นของรูปภาพ ผลลัพธ์ที่ได้เป็นการวิเคราะห์ทางเทคนิคเท่านั้น ไม่ใช่คำตัดสินทางกฎหมาย โปรดใช้วิจารณญาณในการใช้งาน',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  BlocBuilder<ConsentCubit, ConsentState>(
                    builder: (context, state) {
                      final cubit = context.read<ConsentCubit>();
                      return Column(
                        children: [
                          _ConsentTile(
                            value: state.termsAccepted,
                            onChanged: (_) => cubit.toggleTerms(),
                            title: 'ยอมรับเงื่อนไขการใช้งาน',
                            subtitle: 'อ่านข้อกำหนดและนโยบายความเป็นส่วนตัว',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _ConsentTile(
                            value: state.researchConsent,
                            onChanged: (_) => cubit.toggleResearch(),
                            title: 'ยินยอมให้นำข้อมูลไปปรับปรุงระบบ',
                            subtitle: 'ข้อมูลของคุณจะถูกเก็บเป็นความลับเพื่อใช้พัฒนาความแม่นยำของ AI',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: state.canProceed ? () async {
                                await ServiceLocator.authRepository.markOnboardingSeen();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.canProceed ? const Color(0xFF8B9EAA) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'เริ่มใช้งาน',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เวอร์ชัน 1.0.0 • ความปลอดภัยของคุณคือสิ่งสำคัญ',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;
  final bool isDark;

  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        activeColor: const Color(0xFF007293),
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.5),
      ),
    );
  }
}
