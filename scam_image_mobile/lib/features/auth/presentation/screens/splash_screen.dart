import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'กำลังเตรียมระบบ...';

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndConsent();
  }

  Future<void> _checkAuthenticationAndConsent() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ตรวจสอบว่ายอมรับ Consent หรือยัง
      final hasAcceptedConsent = prefs.getBool('consent_accepted') ?? false;
      
      // ตรวจสอบว่าล็อกอินหรือยัง (จำลองจาก Access Token)
      final hasAccessToken = prefs.getString('access_token') != null;

      if (!mounted) return;

      if (!hasAcceptedConsent) {
        context.go('/consent');
      } else if (!hasAccessToken) {
        context.go('/login');
      } else {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.security,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scam Image Detection',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'ระบบตรวจสอบรูปภาพเพื่อความปลอดภัย',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
