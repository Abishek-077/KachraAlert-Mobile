import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color helpers
/// Keeps UI clean and design-system driven
extension ThemeColorsExtension on BuildContext {
  /// Whether the app is currently in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // =========================
  // Text Colors
  // =========================

  Color get textPrimary =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get textTertiary =>
      isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary;

  /// Muted / helper text
  Color get textMuted => isDarkMode
      ? AppColors.darkTextSecondary.withOpacity(0.6)
      : AppColors.textSecondary.withOpacity(0.6);

  // =========================
  // Surfaces & Backgrounds
  // =========================

  Color get backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get surfaceVariantColor =>
      isDarkMode ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

  Color get inputFillColor =>
      isDarkMode ? AppColors.darkInputFill : AppColors.inputFill;

  // =========================
  // Borders & Dividers
  // =========================

  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.border;

  Color get dividerColor =>
      isDarkMode ? AppColors.darkDivider : AppColors.divider;

  // =========================
  // Brand Colors
  // =========================

  Color get primaryColor => AppColors.primary;
  Color get secondaryColor => AppColors.secondary;
  Color get accentGold => AppColors.accentGold;

  // =========================
  // Shadows
  // =========================

  /// Card-level elevation
  List<BoxShadow> get cardShadow =>
      isDarkMode ? AppColors.darkCardShadow : AppColors.cardShadow;

  /// Button / CTA elevation
  List<BoxShadow> get buttonShadow => AppColors.buttonShadow;

  // =========================
  // Gradients
  // =========================

  LinearGradient get primaryGradient =>
      isDarkMode ? AppColors.darkPrimaryGradient : AppColors.primaryGradient;

  LinearGradient get backgroundGradient => AppColors.backgroundGradient;

  LinearGradient get goldGradient => AppColors.goldGradient;
}
