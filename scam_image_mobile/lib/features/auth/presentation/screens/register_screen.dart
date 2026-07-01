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
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: const _RegisterView(),
      ),
    );
  }
}

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
  bool _termsAccepted = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณายอมรับเงื่อนไขการใช้งาน'), backgroundColor: Colors.red),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141F2B) : const Color(0xFFF5F7F9);
    final cardColor = isDark ? const Color(0xFF1E2936) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final primaryColor = const Color(0xFF007293);
    final inputFillColor = isDark ? const Color(0xFF141F2B) : Colors.white;
    final inputBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2936) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield, color: primaryColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'ScamGuard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Register Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: isDark ? Border.all(color: const Color(0xFF334155), width: 1) : null,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'สมัครสมาชิกใหม่',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เข้าร่วมระบบรักษาความปลอดภัยอัจฉริยะ',
                            style: TextStyle(fontSize: 14, color: subtitleColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Name field
                          Text(
                            'ชื่อ-นามสกุล',
                            style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _displayNameController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'กรอกชื่อและนามสกุลของคุณ',
                              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.person_outline, color: subtitleColor),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                          ),
                          const SizedBox(height: 16),

                          // Email field
                          Text(
                            'อีเมล',
                            style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'example@email.com',
                              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.mail_outline, color: subtitleColor),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกอีเมล' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          Text(
                            'รหัสผ่าน',
                            style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'อย่างน้อย 8 ตัวอักษร',
                              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.lock_outline, color: subtitleColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: subtitleColor,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) => (v == null || v.length < 8) ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : null,
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password field
                          Text(
                            'ยืนยันรหัสผ่านอีกครั้ง',
                            style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'กรอกรหัสผ่านเดิมอีกครั้ง',
                              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.sync_lock, color: subtitleColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: subtitleColor,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                              if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Terms checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                                  activeColor: primaryColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(color: subtitleColor.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.5),
                                    children: [
                                      const TextSpan(text: 'ฉันยอมรับ '),
                                      TextSpan(text: 'เงื่อนไขการใช้งาน', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                      const TextSpan(text: ' และ '),
                                      TextSpan(text: 'นโยบายความเป็นส่วนตัว', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                      const TextSpan(text: ' ของระบบ ScamGuard'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return ElevatedButton.icon(
                                  onPressed: state is AuthLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  icon: state is AuthLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.person_add_alt_1),
                                  label: state is AuthLoading
                                      ? const SizedBox.shrink()
                                      : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('หรือ', style: TextStyle(color: subtitleColor, fontSize: 14)),
                              ),
                              Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'มีบัญชีอยู่แล้ว? ',
                                style: TextStyle(color: subtitleColor, fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bottom badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2936) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'END-TO-END ENCRYPTED DATA PROTECTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MockAuthRepository implements AuthRepository {
  @override
  Future<bool> hasValidToken() async => false;
  @override
  Future<User?> getCurrentUser() async => null;
  @override
  Future<User> login({required String email, required String password}) => throw UnimplementedError();
  @override
  Future<User> register({required String email, required String password, required String displayName}) async {
    await Future.delayed(const Duration(seconds: 2));
    return User(id: '1', email: email, displayName: displayName);
  }
  @override
  Future<void> logout() async {}
  @override
  Future<AuthToken?> refreshToken() async => null;
  @override
  Future<void> saveTokens(AuthToken token) => throw UnimplementedError();
  @override
  Future<void> clearTokens() => throw UnimplementedError();
  @override
  Future<bool> hasSeenOnboarding() async => false;
  @override
  Future<void> markOnboardingSeen() async {}
}
