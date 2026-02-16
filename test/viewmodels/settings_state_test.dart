import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/features/settings/presentation/providers/settings_providers.dart';

void main() {
  group('SettingsState (view model)', () {
    test('themeMode is light when dark mode is disabled', () {
      const state = SettingsState(
        onboarded: false,
        isDarkMode: false,
        pickupRemindersEnabled: true,
      );

      expect(state.themeMode, ThemeMode.light);
    });

    test('themeMode is dark when dark mode is enabled', () {
      const state = SettingsState(
        onboarded: true,
        isDarkMode: true,
        pickupRemindersEnabled: true,
      );

      expect(state.themeMode, ThemeMode.dark);
    });

    test('copyWith updates onboarded flag', () {
      const state = SettingsState(
        onboarded: false,
        isDarkMode: false,
        pickupRemindersEnabled: true,
      );

      final updated = state.copyWith(onboarded: true);
      expect(updated.onboarded, isTrue);
      expect(updated.isDarkMode, isFalse);
    });

    test('copyWith updates pickup reminders flag', () {
      const state = SettingsState(
        onboarded: true,
        isDarkMode: false,
        pickupRemindersEnabled: true,
      );

      final updated = state.copyWith(pickupRemindersEnabled: false);
      expect(updated.pickupRemindersEnabled, isFalse);
      expect(updated.onboarded, isTrue);
    });

    test('copyWith keeps same values when no changes are provided', () {
      final now = DateTime(2025, 1, 1);
      final state = SettingsState(
        onboarded: true,
        isDarkMode: true,
        pickupRemindersEnabled: false,
        splashShownAt: now,
      );

      final copied = state.copyWith();
      expect(copied.onboarded, state.onboarded);
      expect(copied.isDarkMode, state.isDarkMode);
      expect(copied.pickupRemindersEnabled, state.pickupRemindersEnabled);
      expect(copied.splashShownAt, now);
    });
  });
}
