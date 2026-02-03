import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';

const _kOnboarded = 'onboarded';
const _kDarkMode = 'darkMode';
const _kPickupReminders = 'pickupReminders';
const _kSplashShownAt = 'splashShownAt';
const _kLanguageCode = 'languageCode';

class SettingsState {
  final bool onboarded;
  final bool isDarkMode;
  final bool pickupRemindersEnabled;
  final DateTime? splashShownAt;
  final String languageCode;

  const SettingsState({
    required this.onboarded,
    required this.isDarkMode,
    required this.pickupRemindersEnabled,
    this.splashShownAt,
    required this.languageCode,
  });

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  Locale get locale => Locale(languageCode);

  SettingsState copyWith({
    bool? onboarded,
    bool? isDarkMode,
    bool? pickupRemindersEnabled,
    DateTime? splashShownAt,
    String? languageCode,
  }) {
    return SettingsState(
      onboarded: onboarded ?? this.onboarded,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pickupRemindersEnabled:
          pickupRemindersEnabled ?? this.pickupRemindersEnabled,
      splashShownAt: splashShownAt ?? this.splashShownAt,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  return SettingsNotifier()..load();
});

final isOnboardedProvider = Provider<AsyncValue<bool>>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (s) => AsyncValue.data(s.onboarded),
    loading: () => const AsyncValue.loading(),
    // If settings fail to load, treat as not onboarded (safe default)
    error: (_, __) => const AsyncValue.data(false),
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return settings?.themeMode ?? ThemeMode.system;
});

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return settings?.locale ?? const Locale('en');
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(const AsyncValue.loading());

  late final Box _box; // untyped: stores bool + int (millis)
  bool _inited = false;

  Future<void> _init() async {
    if (_inited) return;

    // Use an untyped box because we store multiple primitive types
    _box = HiveService.untypedBox(HiveTableConstant.settingsBox);

    _inited = true;
  }

  Future<void> load() async {
    try {
      await _init();

      final onboarded = (_box.get(_kOnboarded, defaultValue: false) as bool);
      final isDarkMode = (_box.get(_kDarkMode, defaultValue: false) as bool);
      final pickupRemindersEnabled =
          (_box.get(_kPickupReminders, defaultValue: true) as bool);
      final languageCode =
          (_box.get(_kLanguageCode, defaultValue: 'en') as String);

      final splashMillis = _box.get(_kSplashShownAt) as int?;
      final splashShownAt = splashMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(splashMillis);

      state = AsyncValue.data(
        SettingsState(
          onboarded: onboarded,
          isDarkMode: isDarkMode,
          pickupRemindersEnabled: pickupRemindersEnabled,
          splashShownAt: splashShownAt,
          languageCode: languageCode,
        ),
      );
    } catch (_) {
      // Safe defaults
      state = const AsyncValue.data(
        SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          splashShownAt: null,
          languageCode: 'en',
        ),
      );
    }
  }

  Future<void> setOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, true);

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    state = AsyncValue.data(current.copyWith(onboarded: true));
  }

  Future<void> resetOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, false);

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    state = AsyncValue.data(current.copyWith(onboarded: false));
  }

  Future<void> toggleTheme() async {
    await _init();

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    final next = !current.isDarkMode;
    await _box.put(_kDarkMode, next);

    state = AsyncValue.data(current.copyWith(isDarkMode: next));
  }

  Future<void> setPickupReminders(bool enabled) async {
    await _init();

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    await _box.put(_kPickupReminders, enabled);

    state = AsyncValue.data(current.copyWith(pickupRemindersEnabled: enabled));
  }

  Future<void> recordSplashShown() async {
    await _init();

    final now = DateTime.now();
    await _box.put(_kSplashShownAt, now.millisecondsSinceEpoch);

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    state = AsyncValue.data(current.copyWith(splashShownAt: now));
  }

  Future<void> setLanguageCode(String languageCode) async {
    await _init();

    final current = state.valueOrNull ??
        const SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
          languageCode: 'en',
        );

    await _box.put(_kLanguageCode, languageCode);
    state = AsyncValue.data(current.copyWith(languageCode: languageCode));
  }
}

/// Ensures splash is shown for at least 1 second overall, and records when it was shown.
/// If splash was already shown within the last 1 second (e.g., hot restart), it returns immediately.
final splashDelayProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(settingsProvider).valueOrNull;
  final now = DateTime.now();
  final lastShown = settings?.splashShownAt;

  if (lastShown != null) {
    final elapsed = now.difference(lastShown);
    if (elapsed < const Duration(seconds: 1)) {
      return;
    }
  }

  await Future<void>.delayed(const Duration(seconds: 1));
  await ref.read(settingsProvider.notifier).recordSplashShown();
});
