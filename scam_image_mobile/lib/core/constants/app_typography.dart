import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTypography — design system text styles.
///
/// Sarabun is used for all UI copy (supports Thai + English).
/// Inter is used for numeric / code data display.
class AppTypography {
  AppTypography._();

  // ── Sarabun styles ───────────────────────────────────────────────────────

  /// 48 / w700 — hero display (rarely used on mobile).
  static TextStyle displayHero({Color? color}) => GoogleFonts.sarabun(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 24 / w700 — primary page titles.
  static TextStyle headlineLgMobile({Color? color}) => GoogleFonts.sarabun(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 22 / w700 — card / section titles.
  static TextStyle titleMd({Color? color}) => GoogleFonts.sarabun(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 18 / w600 — section headers.
  static TextStyle sectionHeader({Color? color}) => GoogleFonts.sarabun(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 16 / w400 — body / paragraph text.
  static TextStyle bodyBase({Color? color}) => GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// 16 / w600 — button labels.
  static TextStyle buttonLabel({Color? color}) => GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 13 / w400 — captions / helper text.
  static TextStyle caption({Color? color}) => GoogleFonts.sarabun(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // ── Inter styles (numbers / code) ────────────────────────────────────────

  /// 14 / w500 Inter — numeric data, risk scores, code snippets.
  static TextStyle codeData({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
