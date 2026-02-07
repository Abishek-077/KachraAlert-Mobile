import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =========================
  // Brand Core (Premium)
  // =========================

  /// Primary: Neo Eco Green (premium, vibrant, trustworthy)
  static const Color primary = Color(0xFF0EA87B); // Emerald Core
  static const Color primaryDark = Color(0xFF0A7A57); // Deep Forest
  static const Color primaryLight = Color(0xFF7CF5C0); // Mint Glow

  /// Secondary: Aqua Pulse (fresh accent)
  static const Color secondary = Color(0xFF22D3EE);
  static const Color secondaryLight = Color(0xFF7ADCF6);

  /// Luxury Accent: Warm Sand (use sparingly for highlights)
  static const Color accentGold = Color(0xFFE3C27A);
  static const Color accentGoldSoft = Color(0xFFF6E7C1);

  /// Supporting accents
  static const Color accentMint = Color(0xFF22C55E);
  static const Color accentCoral = Color(0xFFFF7A7A);

  // =========================
  // Neutrals (Porcelain / Slate)
  // =========================
  static const Color background = Color(0xFFF3FBF9); // Soft mint wash
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F5F1);
  static const Color inputFill = Color(0xFFEEF8F4);

  // Premium dark neutrals
  static const Color textPrimary = Color(0xFF0B1E16); // Deep forest
  static const Color textSecondary = Color(0xFF335447); // Muted green
  static const Color textTertiary = Color(0xFF86A197); // Soft sage

  // Borders & dividers
  static const Color border = Color(0xFFD3E6DE);
  static const Color divider = Color(0xFFE3F1EB);

  // =========================
  // Status (More premium tones)
  // =========================
  static const Color success = Color(0xFF16B364); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFF04438); // Red 500
  static const Color info = Color(0xFF0EA5A5); // Teal 500

  // Auth Primary (keep aligned with brand)
  static const Color authPrimary = Color(0xFF12B76A);

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

  /// Primary gradient: Emerald -> Aqua -> Cyan
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A7A57), // primaryDark
      Color(0xFF0EA87B), // primary
      Color(0xFF22D3EE), // secondary
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Soft background gradient (subtle premium depth)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF3FBF9),
      Color(0xFFFFFFFF),
    ],
  );

  /// Hero gradient: Emerald -> Aqua -> Warm Sand
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA87B),
      Color(0xFF22D3EE),
      Color(0xFFF4D7A0),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Glass panel gradient
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A7A57),
      Color(0xFF0EA5A5),
      Color(0xFF0F766E),
    ],
  );

  /// Gold highlight gradient (use for badges / premium chips)
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF1E2B8),
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
  // Premium Accent Gradients (NEW)
  // =========================

  /// Purple to Pink gradient (achievements, premium features)
  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
  );

  /// Blue to Cyan gradient (water, clean, tech)
  static const LinearGradient blueCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  );

  /// Orange to Red gradient (urgent, critical)
  static const LinearGradient orangeRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );

  /// Teal to Emerald gradient (eco-friendly)
  static const LinearGradient tealEmeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
  );

  /// Mesh gradient for animated backgrounds
  static const List<Color> meshGradientColors = [
    Color(0xFF0EA87B),
    Color(0xFF22D3EE),
    Color(0xFF7CF5C0),
    Color(0xFF0A7A57),
  ];

  // =========================
  // Glassmorphism Colors (NEW)
  // =========================

  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassWhite20 = Color(0x33FFFFFF);
  static const Color glassWhite30 = Color(0x4DFFFFFF);
  static const Color glassBlack10 = Color(0x1A000000);
  static const Color glassBlack20 = Color(0x33000000);

  // =========================
  // Shimmer Effect Colors (NEW)
  // =========================

  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A2A);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3A);

  // =========================
  // Neon Glow Accents (NEW)
  // =========================

  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonPink = Color(0xFFFF0099);

  // =========================
  // Data Visualization Palette (NEW)
  // =========================

  static const List<Color> chartColors = [
    Color(0xFF12B76A), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Green
  ];

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
      Color(0xFF0A7A57),
      Color(0xFF22D3EE),
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
