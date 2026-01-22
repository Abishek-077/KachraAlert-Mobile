import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';

const _kOnboarded = 'onboarded';
const _kDarkMode = 'darkMode';
const _kPickupReminders = 'pickupReminders';

class SettingsState {
  final bool onboarded;
  final bool isDarkMode;
  final bool pickupRemindersEnabled;

  const SettingsState({
    required this.onboarded,
    required this.isDarkMode,
    required this.pickupRemindersEnabled,
  });

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsState copyWith({
    bool? onboarded,
    bool? isDarkMode,
    bool? pickupRemindersEnabled,
  }) {
    return SettingsState(
      onboarded: onboarded ?? this.onboarded,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pickupRemindersEnabled: pickupRemindersEnabled ?? this.pickupRemindersEnabled,
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
    error: (_, __) => const AsyncValue.data(false),
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider).value;
  return settings?.themeMode ?? ThemeMode.system;
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(const AsyncValue.loading());

  late final Box _box; // ✅ untyped
  bool _inited = false;

  Future<void> _init() async {
    if (_inited) return;

    // ✅ IMPORTANT: use untyped box because this box stores bools
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
      state = AsyncValue.data(
        SettingsState(
          onboarded: onboarded,
          isDarkMode: isDarkMode,
          pickupRemindersEnabled: pickupRemindersEnabled,
        ),
      );
    } catch (_) {
      state = const AsyncValue.data(
        SettingsState(
          onboarded: false,
          isDarkMode: false,
          pickupRemindersEnabled: true,
        ),
      );
    }
  }

  Future<void> setOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, true);
    final current =
        state.value ??
        const SettingsState(onboarded: false, isDarkMode: false, pickupRemindersEnabled: true);
    state = AsyncValue.data(current.copyWith(onboarded: true));
  }

  Future<void> resetOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, false);
    final current =
        state.value ??
        const SettingsState(onboarded: false, isDarkMode: false, pickupRemindersEnabled: true);
    state = AsyncValue.data(current.copyWith(onboarded: false));
  }

  Future<void> toggleTheme() async {
    await _init();
    final current =
        state.value ??
        const SettingsState(onboarded: false, isDarkMode: false, pickupRemindersEnabled: true);
    final next = !current.isDarkMode;
    await _box.put(_kDarkMode, next);
    state = AsyncValue.data(current.copyWith(isDarkMode: next));
  }

  Future<void> setPickupReminders(bool enabled) async {
    await _init();
    final current =
        state.value ??
        const SettingsState(onboarded: false, isDarkMode: false, pickupRemindersEnabled: true);
    await _box.put(_kPickupReminders, enabled);
    state = AsyncValue.data(current.copyWith(pickupRemindersEnabled: enabled));
  }

}

final splashDelayProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
});
