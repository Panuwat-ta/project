import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

// ── Text theme helper ────────────────────────────────────────────────────

TextTheme _buildTextTheme(Color bodyColor, Color displayColor) =>
    AppTypography.textTheme(bodyColor);

ThemeData getDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryFixedDim,
    onPrimary: AppColors.bgDark,
    primaryContainer: AppColors.primary,
    onPrimaryContainer: AppColors.inverseOnSurface,
    secondary: AppColors.secondaryContainer,
    onSecondary: AppColors.bgDark,
    secondaryContainer: AppColors.success,
    onSecondaryContainer: AppColors.inverseOnSurface,
    tertiary: AppColors.warning,
    onTertiary: AppColors.bgDark,
    tertiaryContainer: AppColors.tertiary,
    onTertiaryContainer: AppColors.inverseOnSurface,
    error: AppColors.error,
    onError: AppColors.bgDark,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onSurface,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.inverseOnSurface,
    onSurfaceVariant: AppColors.outlineVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.onSurface,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primaryFixedDim,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: _buildTextTheme(
      AppColors.inverseOnSurface,
      AppColors.inverseOnSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.inverseOnSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.sectionHeader(
        color: AppColors.inverseOnSurface,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryFixedDim,
      unselectedItemColor: AppColors.outline,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryFixedDim,
        foregroundColor: AppColors.bgDark,
        minimumSize: const Size(double.infinity, 54),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        textStyle: AppTypography.buttonLabel(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryFixedDim,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppColors.primaryFixedDim),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        textStyle: AppTypography.buttonLabel(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inverseSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.outline, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.primaryFixedDim, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.lgBorder,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      hintStyle: AppTypography.bodyBase(color: AppColors.outline),
      labelStyle: AppTypography.bodyBase(color: AppColors.outlineVariant),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.inverseSurface,
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryFixedDim;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.bgDark),
      side: const BorderSide(color: AppColors.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xsBorder),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.bgDark;
        }
        return AppColors.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryFixedDim;
        }
        return AppColors.inverseSurface;
      }),
    ),
  );
}
