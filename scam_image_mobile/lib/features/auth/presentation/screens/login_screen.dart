import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

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
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: const _LoginView(),
      ),
    );
  }
}

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
    final email = _emailController.text.trim().isEmpty ? 'test@example.com' : _emailController.text.trim();
    final password = _passwordController.text.isEmpty ? 'password' : _passwordController.text;
    
    context.read<AuthBloc>().add(
      LoginRequested(
        email: email,
        password: password,
      ),
    );
  }

  void _showOtherLogins(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2936) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เลือกช่องทางเข้าสู่ระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildLoginOption(
                iconPath: 'assets/icons/facebook.svg',
                label: 'เข้าสู่ระบบด้วย Facebook',
                textColor: textColor,
                isDark: isDark,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildLoginOption(
                iconPath: 'assets/icons/github.svg',
                label: 'เข้าสู่ระบบด้วย GitHub',
                textColor: textColor,
                isDarkIcon: true,
                isDark: isDark,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildLoginOption(
                iconPath: 'assets/icons/line.svg',
                label: 'เข้าสู่ระบบด้วย LINE',
                textColor: textColor,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginOption({
    required String iconPath,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    required bool isDark,
    bool isDarkIcon = false,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: isDarkIcon && isDark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.shield, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ScamGuard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ระบบรักษาความปลอดภัยอัจฉริยะ',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Login Card
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
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 24),

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รหัสผ่าน',
                                style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'ลืมรหัสผ่าน',
                                  style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: '••••••••',
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
                            validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                          ),
                          const SizedBox(height: 16),

                          // Remember me
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  activeColor: primaryColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(color: subtitleColor.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'จดจำการใช้งานของฉัน',
                                style: TextStyle(fontSize: 14, color: subtitleColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return ElevatedButton(
                                  onPressed: state is AuthLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: state is AuthLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                          // Google Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: inputBorderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: isDark ? const Color(0xFF141F2B) : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/google.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text('เข้าสู่ระบบด้วย Google', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Apple Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => _showOtherLogins(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: inputBorderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: isDark ? const Color(0xFF141F2B) : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.more_horiz, color: isDark ? Colors.white : Colors.black, size: 28),
                                  const SizedBox(width: 12),
                                  Text('เข้าสู่ระบบช่องทางอื่นๆ', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ยังไม่มีบัญชีใช่หรือไม่? ',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'สมัครสมาชิก',
                          style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
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

class _MockAuthRepository implements AuthRepository {
  @override
  Future<bool> hasValidToken() async => false;
  @override
  Future<User?> getCurrentUser() async => null;
  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 2));
    return User(id: '1', email: email, displayName: email.split('@').first);
  }
  @override
  Future<User> register({required String email, required String password, required String displayName}) => throw UnimplementedError();
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
