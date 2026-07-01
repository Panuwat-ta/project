import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/splash_cubit.dart';

/// Full-screen Splash Screen — dark-mode atmospheric design.
///
/// Creates a [SplashCubit] with a [_MockAuthRepository] stub and calls
/// [SplashCubit.checkSession] on init.  Navigation is driven by BLoC state
/// via [BlocListener].
///
/// Real DI will be wired in Task 23.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashCubit _cubit;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  // Cycling status text
  static const List<String> _statusMessages = [
    'กำลังเริ่มต้นระบบ...',
    'ตรวจสอบความปลอดภัย...',
    'โหลดฐานข้อมูลล่าสุด...',
    'เตรียมความพร้อม...',
  ];
  int _statusIndex = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    // Logo pulse animation: scale 1.0 → 1.05, 3 s, repeat
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Cycling status text every 2 s
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    });

    // Bootstrap the cubit with the mock repository
    _cubit = SplashCubit(_MockAuthRepository());
    _cubit.checkSession();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _statusTimer?.cancel();
    _cubit.close();
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
      // Navigate to login on any unrecoverable error
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocProvider<SplashCubit>.value(
      value: _cubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: _handleState,
        child: Scaffold(
          backgroundColor: AppColors.bgDark,
          body: Stack(
            children: [
              // ── Dot-grid background pattern ───────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),

              // ── Atmospheric glow — top-left (primary) ────────────────────
              Positioned(
                top: -size.height * 0.1,
                left: -size.width * 0.1,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      width: size.width * 0.5,
                      height: size.height * 0.5,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Atmospheric glow — bottom-right (success/secondary) ───────
              Positioned(
                bottom: -size.height * 0.1,
                right: -size.width * 0.1,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      width: size.width * 0.6,
                      height: size.height * 0.6,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main content ──────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeMargin,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top spacer
                      const SizedBox(height: 64),

                      // ── Brand identity ────────────────────────────────────
                      Column(
                        children: [
                          // Animated logo
                          AnimatedBuilder(
                            animation: _logoScale,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              );
                            },
                            child: _LogoContainer(),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // App name
                          Text(
                            'Scam Image Detection',
                            style: AppTypography.headlineLgMobile(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Thai subtitle
                          Text(
                            'ตรวจจับรูปภาพหลอกลวง',
                            style: AppTypography.titleMd(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Security badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFF7CF994), // secondaryFixed
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Secure & Reliable',
                                style: AppTypography.caption(
                                  color: const Color(0xFF7CF994),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // ── Bottom loading section ────────────────────────────
                      Column(
                        children: [
                          // Circular progress indicator
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Cycling status text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              _statusMessages[_statusIndex],
                              key: ValueKey<int>(_statusIndex),
                              style: AppTypography.bodyBase(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Version label
                          Text(
                            'ScamGuard v1.0.0',
                            style: AppTypography.caption(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo container widget ──────────────────────────────────────────────────────

class _LogoContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Outer glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Glass card
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: const Icon(
            Icons.shield,
            size: 80,
            color: Colors.white,
          ),
        ),

        // Search badge — bottom-right overlay
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.primaryFixedDim,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dot-grid background painter ───────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 40.0;
    const double radius = 1.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

// ── Bootstrap mock repository (replaced by real DI in Task 23) ───────────────

class _MockAuthRepository implements AuthRepository {
  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<AuthToken?> refreshToken() => throw UnimplementedError();

  @override
  Future<void> saveTokens(AuthToken token) => throw UnimplementedError();

  @override
  Future<void> clearTokens() => throw UnimplementedError();
}
