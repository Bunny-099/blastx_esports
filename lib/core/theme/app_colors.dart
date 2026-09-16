import 'package:flutter/material.dart';

/// ============================================================
/// APP COLORS — "Sexy" Premium Free Fire Theme
/// ============================================================
/// Deep cinematic dark base + fire orange/red gradient accents
/// + gold highlights for premium (prize pool) elements.
/// Treatment is glassmorphism + soft glow, not flat/harsh neon.
/// ============================================================

class AppColors {
  AppColors._();

  // ---------------- Base ----------------
  static const Color background = Color(0xFF0B0B10);
  static const Color backgroundElevated = Color(0xFF131319);
  static const Color surface = Color(0xFF16161D);
  static const Color surfaceMuted = Color(0xFF1F1F28);
  static const Color border = Color(0x1FFFFFFF); // hairline glass border

  // ---------------- Primary — Free Fire Orange ----------------
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryDark = Color(0xFFE85A00);
  static const Color primaryLight = Color(0xFFFF9142);

  // ---------------- Secondary — Blood Red ----------------
  static const Color secondary = Color(0xFFFF2E2E);
  static const Color secondaryDark = Color(0xFFD91E1E);
  static const Color secondaryLight = Color(0xFFFF6B6B);

  // ---------------- Gold — premium accents ----------------
  static const Color gold = Color(0xFFFFC93C);
  static const Color goldDark = Color(0xFFE0A82E);

  // ---------------- Text ----------------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C2);
  static const Color textMuted = Color(0xFF6E6E7A);

  // ---------------- Status ----------------
  static const Color success = Color(0xFF3DDC84);
  static const Color error = Color(0xFFFF3B3B);
  static const Color warning = Color(0xFFFFB020);

  // ---------------- Gradients ----------------
  static const List<Color> primaryGradient = [primary, secondary];

  static const LinearGradient fireGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE9A8), gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle "breathing" ambient blobs used behind screens
  static const RadialGradient ambientGlowOrange = RadialGradient(
    colors: [Color(0x33FF6B00), Color(0x00FF6B00)],
    radius: 0.85,
  );

  static const RadialGradient ambientGlowRed = RadialGradient(
    colors: [Color(0x26FF2E2E), Color(0x00FF2E2E)],
    radius: 0.85,
  );

  // Frosted glass card fill
  static const LinearGradient glassFill = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient border that fades from an accent color into transparency.
  /// Used to wrap glass cards for the soft neon-edge look.
  static LinearGradient glassBorder(Color accent) => LinearGradient(
    colors: [
      accent.withOpacity(0.9),
      accent.withOpacity(0.15),
      Colors.transparent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}