import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.sarabun().fontFamily,
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(88, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(88, 44),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkSurface,
        onSurfaceVariant: AppColors.darkTextSecondary,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: GoogleFonts.sarabun().fontFamily,
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(88, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(88, 44),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color defaultColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final Color secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.sarabun(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.02,
        color: defaultColor,
      ),
      headlineLarge: GoogleFonts.sarabun(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: defaultColor,
      ),
      titleMedium: GoogleFonts.sarabun(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        color: defaultColor,
      ),
      titleSmall: GoogleFonts.sarabun(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: defaultColor,
      ),
      bodyLarge: GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: defaultColor,
      ),
      bodyMedium: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 20 / 16,
        color: defaultColor,
      ),
      bodySmall: GoogleFonts.sarabun(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: secondaryColor,
      ),
    );
  }
}
