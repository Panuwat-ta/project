
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../bloc/splash_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashCubit>().checkSession();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _handleState(BuildContext context, SplashState state) {
    if (state is SplashAuthenticated) {
      context.go('/main/home');
    } else if (state is SplashUnauthenticated) {
      context.go('/login');
    } else if (state is SplashConsentRequired) {
      context.go('/onboarding');
    } else if (state is SplashFailure) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<SplashCubit, SplashState>(
      listener: _handleState,
      child: Scaffold(
        body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF141F2B), const Color(0xFF0F151B)]
                    : [const Color(0xFF007293), const Color(0xFF005873)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeMargin,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Brand identity
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _logoScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            );
                          },
                          child: const _LogoContainer(),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Scam Image Detection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ตรวจจับรูปภาพหลอกลวง',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF4ADE80),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SECURE & RELIABLE',
                              style: TextStyle(
                                color: const Color(0xFF4ADE80),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bottom loading section
                    Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ตรวจสอบความปลอดภัย...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ScamGuard v1.0.0',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}

class _LogoContainer extends StatelessWidget {
  const _LogoContainer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glass card
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shield,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        // Search badge
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF233242) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.search,
              size: 28,
              color: isDark ? Colors.white : const Color(0xFF007293),
              weight: 700,
            ),
          ),
        ),
      ],
    );
  }
}

