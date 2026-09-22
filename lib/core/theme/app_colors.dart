import 'package:flutter/material.dart';

/// ============================================================
/// APP COLORS — "Blastix" Dark Premium Neon-Cyan Palette
/// ============================================================
/// Deep navy base (#061A2B) + premium neon cyan (#0FFCBE) accents
/// + cyan ice gradients and soft ambient teal glows.
/// Completely free of orange, red, or gold hues.
/// ============================================================

class AppColors {
  AppColors._();

  // ---------------- Base Tokens ----------------
  static const Color bgBlack = Color(0xFF000000);
  static const Color bgDeep = Color(0xFF02080D);
  static const Color bgNavy = Color(0xFF061A2B);
  static const Color surfaceNavy = Color(0xFF0B2235);
  static const Color surfaceElevated = Color(0xFF122E43);

  // Base Aliases
  static const Color background = bgNavy;
  static const Color backgroundElevated = surfaceElevated;
  static const Color surface = surfaceElevated;
  static const Color surfaceMuted = surfaceNavy;

  // ---------------- Borders ----------------
  static const Color borderSubtle = Color(0xFF1E2E3C);
  static const Color borderCyan = Color(0x1F0FFCBE); // rgba(15, 252, 190, 0.12)
  static const Color border = borderSubtle;

  // ---------------- Accent Tokens ----------------
  static const Color primaryNeon = Color(0xFF0FFCBE);
  static const Color primaryDark = Color(0xFF0AB085);
  static const Color primaryDeep = Color(0xFF087E5F);
  static const Color glowSoft = Color(0xFF57FDD2);
  static const Color glowLight = Color(0xFFB7FEEC);

  // Accent Aliases
  static const Color primary = primaryNeon;
  static const Color primaryLight = glowLight;
  static const Color secondary = primaryDeep;
  static const Color secondaryDark = Color(0xFF05523E);
  static const Color secondaryLight = glowSoft;

  // Highlights & Prize Pool
  static const Color gold = glowLight;
  static const Color goldDark = glowSoft;

  // ---------------- Text Tokens ----------------
  static const Color textPrimary = Color(0xFFF4F7F8);
  static const Color textSecondary = Color(0xFFB4BABF);
  static const Color textMuted = Color(0xFF72808C);

  // ---------------- Status (Teal/Cyan themed) ----------------
  static const Color success = primaryNeon;
  static const Color error = primaryDeep;
  static const Color warning = glowSoft;

  // ---------------- Gradients ----------------
  static const List<Color> primaryGradient = [bgNavy, primaryNeon];

  static const LinearGradient blastixCoreGradient = LinearGradient(
    colors: [bgNavy, primaryNeon],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Alias for backward compatibility
  static const LinearGradient fireGradient = blastixCoreGradient;

  static const LinearGradient cyanIceGradient = LinearGradient(
    colors: [primaryNeon, Color(0xFFCFFEF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Alias for backward compatibility
  static const LinearGradient goldGradient = cyanIceGradient;

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [bgNavy, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle ambient radial glows
  static const RadialGradient ambientGlowCyan = RadialGradient(
    colors: [Color(0x2657FDD2), Colors.transparent], // Glow/Soft at ~15% opacity
    radius: 0.85,
  );

  static const RadialGradient ambientGlowOrange = ambientGlowCyan;

  static const RadialGradient ambientGlowLight = RadialGradient(
    colors: [Color(0x1FB7FEEC), Colors.transparent], // Glow/Light at ~12% opacity
    radius: 0.85,
  );

  static const RadialGradient ambientGlowRed = ambientGlowLight;

  // Frosted glass card fill — navy-tinted rgba(6, 26, 43, 0.55)
  static const LinearGradient glassFill = LinearGradient(
    colors: [Color(0x8C061A2B), Color(0x40061A2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient border that fades from an accent color into transparency.
  /// Used to wrap glass cards for the soft neon-edge look.
  static LinearGradient glassBorder(Color accent) => LinearGradient(
    colors: [
      accent.withValues(alpha: 0.9),
      accent.withValues(alpha: 0.15),
      Colors.transparent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}