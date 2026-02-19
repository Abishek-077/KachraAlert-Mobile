import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';
import 'package:smart_waste_app/features/settings/presentation/providers/settings_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_motion_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveTableConstant.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persists and loads reduceMotion and hapticsEnabled', () async {
    final notifier = SettingsNotifier();
    await notifier.load();

    final initial = notifier.state.valueOrNull;
    expect(initial?.reduceMotion, isFalse);
    expect(initial?.hapticsEnabled, isTrue);

    await notifier.setReduceMotion(true);
    await notifier.setHapticsEnabled(false);

    final reloaded = SettingsNotifier();
    await reloaded.load();

    final state = reloaded.state.valueOrNull;
    expect(state, isNotNull);
    expect(state!.reduceMotion, isTrue);
    expect(state.hapticsEnabled, isFalse);
  });
}
