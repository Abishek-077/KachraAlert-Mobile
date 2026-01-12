import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';
import 'package:smart_waste_app/core/services/sound/sound_service.dart';
import 'package:smart_waste_app/features/admin/data/models/admin_alert_hive_model.dart';

/// ✅ Starts listening to admin broadcasts and plays sound when new one arrives.
/// This works when app is open / running.
final globalAdminAlertSoundListenerProvider = Provider<StreamSubscription>((
  ref,
) {
  final Box<AdminAlertHiveModel> box = HiveService.box<AdminAlertHiveModel>(
    HiveTableConstant.adminAlertsBox,
  );

  final sub = box.watch().listen((event) async {
    // Only play on add/update, ignore deletes
    if (event.deleted) return;

    // ✅ play sound
    await SoundService.playAlert();
  });

  ref.onDispose(() => sub.cancel());
  return sub;
});
