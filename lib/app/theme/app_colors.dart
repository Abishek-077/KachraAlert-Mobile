import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =========================
  // Brand Core (Premium)
  // =========================

  /// Primary: Municipal Green (used for CTAs, selected states, success)
  static const Color primary = Color(0xFF1F8F5B);
  static const Color primaryDark = Color(0xFF156A44);
  static const Color primaryLight = Color(0xFF62C58E);

  /// Secondary: Teal Mist (fresh accent)
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryLight = Color(0xFF93C5FD);

  /// Luxury Accent: Warm Sand (use sparingly for highlights)
  static const Color accentGold = Color(0xFFD6B25E);
  static const Color accentGoldSoft = Color(0xFFF2E7C9);

  /// Supporting accents
  static const Color accentMint = Color(0xFF22C55E);
  static const Color accentCoral = Color(0xFFF87171);

  // =========================
  // Neutrals (Porcelain / Slate)
  // =========================
  static const Color background = Color(0xFFF6F8F7); // Neutral light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F4F3);
  static const Color inputFill = Color(0xFFF2F4F3);

  // Premium dark neutrals
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);

  // Borders & dividers
  static const Color border = Color(0xFFE3E7E6);
  static const Color divider = Color(0xFFE5E7EB);

  // =========================
  // Status (More premium tones)
  // =========================
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF1D4ED8);

  // Auth Primary (keep aligned with brand)
  static const Color authPrimary = primary;

  // =========================
  // Opacity helpers
  // =========================
  static const Color white90 = Color(0xE6FFFFFF);
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);

  static const Color black10 = Color(0x1A000000);
  static const Color black20 = Color(0x33000000);
  static const Color black40 = Color(0x66000000);

  // =========================
  // Gradients (Premium)
  // =========================

  /// Primary gradient: Midnight Indigo -> Electric Blue
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF156A44),
      Color(0xFF1F8F5B),
      Color(0xFF2563EB),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Soft background gradient (subtle premium depth)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF6F8F7),
      Color(0xFFFFFFFF),
    ],
  );

  /// Gold highlight gradient (use for badges / premium chips)
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF2E7C9),
      Color(0xFFD6B25E),
    ],
  );

  /// Status gradients (cleaner than before)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
  );

  // =========================
  // Dark Theme (Premium dark)
  // =========================
  static const Color darkBackground = Color(0xFF0B1020); // Deep Navy
  static const Color darkSurface = Color(0xFF111827); // Slate 900
  static const Color darkSurfaceVariant = Color(0xFF1F2937); // Slate 800
  static const Color darkInputFill = Color(0xFF0F172A); // Slate 900-ish

  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFFB6C2CF);
  static const Color darkTextTertiary = Color(0xFF7B8794);

  static const Color darkBorder = Color(0xFF243244);
  static const Color darkDivider = Color(0xFF1C2636);

  /// Dark primary gradient (midnight + cyan glow)
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B1020),
      Color(0xFF0B8B52),
      Color(0xFF2DD4BF),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  // =========================
  // Shadows (More premium)
  // =========================

  /// Card shadow: soft, wide, modern
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A1F2AFF),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  /// Button shadow: slightly stronger, brand-tinted
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x331F2AFF),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// Dark shadows
  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];

  // =========================
  // Compatibility aliases (older UI files)
  // =========================

  /// Seed used by ColorScheme.fromSeed
  static const Color seed = primary;

  /// Legacy aliases used in some screens/widgets
  static const Color text = textPrimary;
  static const Color subText = textSecondary;
}
