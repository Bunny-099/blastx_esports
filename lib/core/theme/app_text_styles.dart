import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ============================================================
/// APP TEXT STYLES
/// ============================================================
/// Headings — Rajdhani: sharp, condensed, esports/HUD feel.
/// Body     — Manrope: clean and highly readable at small sizes.
/// ============================================================

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.rajdhani(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingXl => GoogleFonts.rajdhani(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingLg => GoogleFonts.rajdhani(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingMd => GoogleFonts.rajdhani(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLg => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMd => GoogleFonts.manrope(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySm => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle get caption => GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textMuted,
  );

  static TextStyle get overline => GoogleFonts.rajdhani(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => GoogleFonts.rajdhani(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.textPrimary,
  );
}