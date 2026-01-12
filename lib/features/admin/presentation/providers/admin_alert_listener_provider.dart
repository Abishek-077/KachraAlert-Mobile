import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/core/services/sound/sound_service.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';

import '../../data/models/admin_alert_hive_model.dart';

final adminAlertListenerProvider = Provider<StreamSubscription>((ref) {
  final box = HiveService.box<AdminAlertHiveModel>(
    HiveTableConstant.adminAlertsBox,
  );

  // Listen to changes (adds/updates)
  final sub = box.watch().listen((event) async {
    // when a new alert is added
    if (event.deleted) return;
    await SoundService.playAlert();
  });

  ref.onDispose(() => sub.cancel());
  return sub;
});
