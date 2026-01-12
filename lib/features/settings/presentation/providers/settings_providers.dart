import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';

const _kOnboarded = 'onboarded';
const _kDarkMode = 'darkMode';

class SettingsState {
  final bool onboarded;
  final bool isDarkMode;
  const SettingsState({required this.onboarded, required this.isDarkMode});

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsState copyWith({bool? onboarded, bool? isDarkMode}) {
    return SettingsState(
      onboarded: onboarded ?? this.onboarded,
      isDarkMode: isDarkMode ?? this.isDarkMode,
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

      state = AsyncValue.data(
        SettingsState(onboarded: onboarded, isDarkMode: isDarkMode),
      );
    } catch (_) {
      state = const AsyncValue.data(
        SettingsState(onboarded: false, isDarkMode: false),
      );
    }
  }

  Future<void> setOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, true);
    final current =
        state.value ?? const SettingsState(onboarded: false, isDarkMode: false);
    state = AsyncValue.data(current.copyWith(onboarded: true));
  }

  Future<void> resetOnboarded() async {
    await _init();
    await _box.put(_kOnboarded, false);
    final current =
        state.value ?? const SettingsState(onboarded: false, isDarkMode: false);
    state = AsyncValue.data(current.copyWith(onboarded: false));
  }

  Future<void> toggleTheme() async {
    await _init();
    final current =
        state.value ?? const SettingsState(onboarded: false, isDarkMode: false);
    final next = !current.isDarkMode;
    await _box.put(_kDarkMode, next);
    state = AsyncValue.data(current.copyWith(isDarkMode: next));
  }
}
