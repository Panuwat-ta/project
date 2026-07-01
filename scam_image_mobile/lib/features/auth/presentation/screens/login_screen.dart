import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

// ── Bootstrap mock repository (replaced by real DI in Task 23) ───────────────

class _MockAuthRepository implements AuthRepository {
  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 2));
    // Demo: any non-empty email/password logs in
    return User(
      id: '1',
      email: email,
      displayName: email.split('@').first,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<AuthToken?> refreshToken() async => null;

  @override
  Future<void> saveTokens(AuthToken token) async {}

  @override
  Future<void> clearTokens() async {}
}

// ── LoginScreen ───────────────────────────────────────────────────────────────

/// Dark-mode login screen with atmospheric blur background.
///
/// Creates an [AuthBloc] with a [_MockAuthRepository] stub.
/// Real DI wired in Task 23.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AuthBloc(_MockAuthRepository());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _bloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/main/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: const _LoginView(),
      ),
    );
  }
}

// ── Login view ────────────────────────────────────────────────────────────────

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Atmospheric glow — top-right ──────────────────────────────
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.1,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: size.width * 0.55,
                  height: size.height * 0.45,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // ── Atmospheric glow — bottom-left ────────────────────────────
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.1,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: size.width * 0.6,
                  height: size.height * 0.5,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.safeMargin,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Brand section ─────────────────────────────────
                      _BrandSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── GlassCard form ────────────────────────────────
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'เข้าสู่ระบบ',
                                style: AppTypography.titleMd(
                                    color: Colors.white),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'อีเมล',
                                  hint: 'example@email.com',
                                  prefixIcon: Icons.mail_outline,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'กรุณากรอกอีเมล';
                                  }
                                  if (!v.contains('@')) {
                                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'รหัสผ่าน',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.outlineVariant,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    tooltip: _obscurePassword
                                        ? 'แสดงรหัสผ่าน'
                                        : 'ซ่อนรหัสผ่าน',
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'กรุณากรอกรหัสผ่าน';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Navigate to forgot password
                                  },
                                  child: Text(
                                    'ลืมรหัสผ่าน',
                                    style: AppTypography.caption(
                                      color: AppColors.primaryFixedDim,
                                    ),
                                  ),
                                ),
                              ),

                              // Remember me checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) {
                                        setState(() {
                                          _rememberMe = v ?? false;
                                        });
                                      },
                                      activeColor: AppColors.primaryFixedDim,
                                      checkColor: AppColors.bgDark,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _rememberMe = !_rememberMe),
                                    child: Text(
                                      'จดจำการใช้งานของฉัน',
                                      style: AppTypography.bodyBase(
                                        color: AppColors.outlineVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Login button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return PrimaryButton(
                                    label: 'เข้าสู่ระบบ',
                                    isLoading: state is AuthLoading,
                                    onPressed: _submit,
                                  );
                                },
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Divider with "หรือ"
                              _OrDivider(),

                              const SizedBox(height: AppSpacing.lg),

                              // Google login button
                              _GoogleLoginButton(),

                              const SizedBox(height: AppSpacing.lg),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ยังไม่มีบัญชี? ',
                                      style: AppTypography.bodyBase(
                                        color: AppColors.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go('/register'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'สมัครสมาชิก',
                                      style: AppTypography.bodyBase(
                                        color: AppColors.primaryFixedDim,
                                      ),
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTypography.bodyBase(color: AppColors.outlineVariant),
      hintStyle: AppTypography.bodyBase(
          color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      prefixIcon: Icon(prefixIcon, color: AppColors.outlineVariant, size: 20),
      filled: true,
      fillColor: AppColors.inverseSurface.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryFixedDim),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      errorStyle: AppTypography.caption(color: AppColors.error),
    );
  }
}

// ── Brand section ─────────────────────────────────────────────────────────────

class _BrandSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shield icon box
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'ScamGuard',
          style: AppTypography.headlineLgMobile(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'ระบบรักษาความปลอดภัยอัจฉริยะ',
          style: AppTypography.bodyBase(
            color: AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

// ── Or divider ────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'หรือ',
            style: AppTypography.caption(
              color: AppColors.outlineVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

// ── Google login button ───────────────────────────────────────────────────────

class _GoogleLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          // TODO: Implement Google login (Task 23)
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          shape: const StadiumBorder(),
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo using coloured text as a simple stand-in
            // (replace with SVG asset when available)
            const _GoogleLogo(),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'เข้าสู่ระบบด้วย Google',
                style: AppTypography.buttonLabel(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    // Simple coloured "G" representation until a real SVG asset is added
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw coloured arcs to approximate Google logo
    const sweepAngle = 3.14159 / 2; // 90°

    final colors = [
      const Color(0xFF4285F4), // blue
      const Color(0xFF34A853), // green
      const Color(0xFFFBBC05), // yellow
      const Color(0xFFEA4335), // red
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1),
        sweepAngle * i,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
