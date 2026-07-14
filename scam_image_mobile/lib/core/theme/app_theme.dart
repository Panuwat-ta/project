import 'package:flutter/material.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// AppTheme — provides dark and light [ThemeData] built from design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => getDarkTheme();
  static ThemeData get light => getLightTheme();
}
