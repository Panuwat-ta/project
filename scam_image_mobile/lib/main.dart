import 'package:flutter/material.dart';
import 'package:scam_image_mobile/core/router/app_router.dart';
import 'package:scam_image_mobile/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScamGuardApp());
}

class ScamGuardApp extends StatelessWidget {
  const ScamGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scam Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // ตรวจสอบและใช้ธีมตามระบบอุปกรณ์ของผู้ใช้
      routerConfig: AppRouter.router,
    );
  }
}
