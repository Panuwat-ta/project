import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

// ── Text theme helper ────────────────────────────────────────────────────

TextTheme _buildTextTheme(Color bodyColor, Color displayColor) =>
    AppTypography.textTheme(bodyColor);

ThemeData getLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.bgDark,
    secondary: AppColors.success,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onPrimary,
    tertiaryContainer: AppColors.warning,
    onTertiaryContainer: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.textPrimary,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.surfaceDark,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.sectionHeader(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 54),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        textStyle: AppTypography.buttonLabel(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        textStyle: AppTypography.buttonLabel(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      hintStyle: AppTypography.bodyBase(color: AppColors.textSecondary),
      labelStyle: AppTypography.bodyBase(color: AppColors.textSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.onPrimary),
      side: const BorderSide(color: AppColors.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xsBorder),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.onPrimary;
        }
        return AppColors.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.border;
      }),
    ),
  );
}
