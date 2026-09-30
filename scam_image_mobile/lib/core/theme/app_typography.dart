import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ScamGuard typography authority. Sarabun is used for UI copy; Inter is
/// reserved for numeric/technical data. Heights are tuned for Thai glyphs.
class AppTypography {
  AppTypography._();

  static const double displayHeroSize = 40;
  static const double headlineSize = 24;
  static const double titleSize = 20;
  static const double sectionSize = 18;
  static const double bodySize = 16;
  static const double buttonSize = 16;
  static const double captionSize = 13;
  static const double codeSize = 14;

  static const double displayHeroHeight = 1.2;
  static const double headlineHeight = 1.35;
  static const double titleHeight = 1.35;
  static const double sectionHeight = 1.4;
  static const double bodyHeight = 1.5;
  static const double buttonHeight = 1.3;
  static const double captionHeight = 1.4;
  static const double codeHeight = 1.35;

  static TextStyle displayHero({Color? color}) => GoogleFonts.sarabun(
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle headlineLgMobile({Color? color}) => GoogleFonts.sarabun(
    fontSize: 24,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle titleMd({Color? color}) => GoogleFonts.sarabun(
    fontSize: 20,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle sectionHeader({Color? color}) => GoogleFonts.sarabun(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle bodyBase({Color? color}) => GoogleFonts.sarabun(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle buttonLabel({Color? color}) => GoogleFonts.sarabun(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle caption({Color? color}) => GoogleFonts.sarabun(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle codeData({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextTheme textTheme(Color color) => TextTheme(
    headlineMedium: headlineLgMobile(color: color),
    titleLarge: titleMd(color: color),
    titleMedium: sectionHeader(color: color),
    bodyLarge: bodyBase(color: color),
    bodyMedium: bodyBase(color: color),
    bodySmall: caption(color: color),
    labelLarge: buttonLabel(color: color),
    labelMedium: caption(color: color),
  );
}
