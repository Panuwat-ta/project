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
import '../bloc/consent_cubit.dart';

// ── Mock repository stub (replaced by real DI in Task 23) ────────────────────

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
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return User(id: '1', email: email, displayName: displayName);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthToken?> refreshToken() async => null;

  @override
  Future<void> saveTokens(AuthToken token) async {}

  @override
  Future<void> clearTokens() async {}
}

// ── RegisterScreen ────────────────────────────────────────────────────────────

/// Dark-mode registration screen with atmospheric blur background.
///
/// Creates an [AuthBloc] with [_MockAuthRepository].
/// Real DI wired in Task 23.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _bloc),
        BlocProvider<ConsentCubit>(create: (_) => ConsentCubit()),
      ],
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
        child: const _RegisterView(),
      ),
    );
  }
}

// ── Register view ─────────────────────────────────────────────────────────────

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit(ConsentState consentState) {
    if (!_formKey.currentState!.validate()) return;
    if (!consentState.termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับเงื่อนไขการใช้งาน'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
          RegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                      _BrandHeader(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── GlassCard form ────────────────────────────────
                      GlassCard(
                        child: BlocBuilder<ConsentCubit, ConsentState>(
                          builder: (context, consentState) {
                            final cubit = context.read<ConsentCubit>();
                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'สมัครสมาชิก',
                                    style: AppTypography.titleMd(
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Display Name
                                  TextFormField(
                                    controller: _displayNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: const TextStyle(
                                        color: Colors.white),
                                    decoration: _inputDecoration(
                                      label: 'ชื่อที่แสดง',
                                      hint: 'กรอกชื่อของคุณ',
                                      prefixIcon: Icons.person_outline,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'กรุณากรอกชื่อที่แสดง';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    style: const TextStyle(
                                        color: Colors.white),
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

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                        color: Colors.white),
                                    decoration: _inputDecoration(
                                      label: 'รหัสผ่าน',
                                      hint: 'ขั้นต่ำ 8 ตัวอักษร',
                                      prefixIcon: Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: AppColors.outlineVariant,
                                        ),
                                        onPressed: () => setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        }),
                                        tooltip: _obscurePassword
                                            ? 'แสดงรหัสผ่าน'
                                            : 'ซ่อนรหัสผ่าน',
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'กรุณากรอกรหัสผ่าน';
                                      }
                                      if (v.length < 8) {
                                        return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  // Confirm Password
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirm,
                                    style: const TextStyle(
                                        color: Colors.white),
                                    decoration: _inputDecoration(
                                      label: 'ยืนยันรหัสผ่าน',
                                      hint: 'กรอกรหัสผ่านอีกครั้ง',
                                      prefixIcon: Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: AppColors.outlineVariant,
                                        ),
                                        onPressed: () => setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        }),
                                        tooltip: _obscureConfirm
                                            ? 'แสดงรหัสผ่าน'
                                            : 'ซ่อนรหัสผ่าน',
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'กรุณายืนยันรหัสผ่าน';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'รหัสผ่านไม่ตรงกัน';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  // Terms checkbox
                                  ConsentCheckboxTile(
                                    value: consentState.termsAccepted,
                                    onChanged: (_) =>
                                        cubit.toggleTerms(),
                                    label:
                                        'ฉันยอมรับเงื่อนไขการใช้งาน',
                                    description:
                                        'จำเป็นต้องยอมรับเพื่อสมัครสมาชิก',
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // Register button
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, authState) {
                                      return PrimaryButton(
                                        label: 'สมัครสมาชิก',
                                        isLoading:
                                            authState is AuthLoading,
                                        enabled:
                                            consentState.termsAccepted,
                                        onPressed: consentState
                                                .termsAccepted
                                            ? () =>
                                                _submit(consentState)
                                            : null,
                                      );
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // Login link
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'มีบัญชีอยู่แล้ว? ',
                                        style: AppTypography.bodyBase(
                                          color: AppColors.outlineVariant,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.go('/login'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                        child: Text(
                                          'เข้าสู่ระบบ',
                                          style: AppTypography.bodyBase(
                                            color:
                                                AppColors.primaryFixedDim,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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

// ── Brand header ──────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          'สร้างบัญชีผู้ใช้ใหม่',
          style: AppTypography.bodyBase(color: AppColors.outlineVariant),
        ),
      ],
    );
  }
}
