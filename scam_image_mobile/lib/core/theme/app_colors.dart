import 'package:flutter/material.dart';

/// AppColors — all design system color tokens.
/// Dark mode tokens are the primary palette; light mode tokens are provided
/// for ThemeData construction.
class AppColors {
  AppColors._();

  // ── Dark Mode Backgrounds ────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F1720);
  static const Color surfaceDark = Color(0xFF162230);
  static const Color inverseSurface = Color(0xFF27313C);

  // ── Light Mode Backgrounds ───────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF6F8FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF006685);
  static const Color primaryFixedDim = Color(0xFF6CD2FF); // dark-mode accent
  static const Color primaryContainer = Color(0xFF00A6D6);

  // ── Risk / Status / Semantic ─────────────────────────────────────────────
  static const Color secondary = Color(0xFF006E2D);
  static const Color tertiary = Color(0xFF855300);
  static const Color danger = Color(0xFFDC2626);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFD68900);
  static const Color success = Color(0xFF006E2D);
  static const Color successDark = Color(0xFF62DF7D);
  static const Color warningDark = Color(0xFFFFB95F);
  static const Color dangerDark = Color(0xFFFFB4AB);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF17212B);
  static const Color textSecondary = Color(0xFF5E6B78);

  // ── Outline / Border ─────────────────────────────────────────────────────
  static const Color outlineVariant = Color(0xFFBDC8CF);
  static const Color outline = Color(0xFF6E797F);
  static const Color border = Color(0xFFD8E0EA);

  // ── Semantic aliases (Material 3 naming) ─────────────────────────────────
  static const Color secondaryContainer = Color(0xFF7CF994);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF121C26);
  static const Color onSurfaceVariant = Color(0xFF3D484E);
  static const Color inversePrimary = Color(0xFF6CD2FF);
  static const Color onBackground = Color(0xFF121C26);
  static const Color inverseOnSurface = Color(0xFFE8F2FF);

  // ── Neutral / component surfaces ────────────────────────────────────────
  static const Color settingsBgDark = Color(0xFF141921);
  static const Color settingsBgLight = Color(0xFFF5F6F8);
  static const Color settingsSurfaceDark = Color(0xFF1B222C);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color neutral50 = Color(0xFFF8F9FA);
  static const Color softSurface = Color(0xFFF0F4F8);
  static const Color thumbnailSurface = Color(0xFFE4EFFD);
  static const Color primarySoft = Color(0xFFDFF1FF);
  static const Color primarySoftAlt = Color(0xFFEAF5FF);
  static const Color primarySoftMuted = Color(0xFFF0F5FF);
  static const Color darkIconSurface = Color(0xFF2A3441);

  // ── Risk supporting surfaces ────────────────────────────────────────────
  static const Color dangerDarkSurface = Color(0xFF3F191D);
  static const Color dangerDarkContainer = Color(0xFF4A1818);
  static const Color dangerDarkForeground = Color(0xFFFFB4B4);
  static const Color dangerLightContainer = Color(0xFFFFEBEB);
  static const Color successDarkForeground = Color(0xFF7CF994);
  static const Color successDarkText = Color(0xFF006E2D);
}
