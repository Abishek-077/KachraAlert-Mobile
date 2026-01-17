import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';
import 'package:smart_waste_app/core/services/sound/sound_service.dart';
import 'package:smart_waste_app/features/admin/data/models/admin_alert_hive_model.dart';
import 'package:smart_waste_app/features/auth/data/models/user_session_hive_model.dart';

class AdminBroadcastSoundGate {
  static Future<UserSessionHiveModel> playIfNeeded({
    required UserSessionHiveModel session,
  }) async {
    // Only residents should "receive" broadcast sound
    if (session.role == 'admin_driver') return session;

    final box = HiveService.box<AdminAlertHiveModel>(
      HiveTableConstant.adminAlertsBox,
    );
    if (box.values.isEmpty) return session;

    // Find latest broadcast createdAt
    final latest = box.values.reduce(
      (a, b) => a.createdAt > b.createdAt ? a : b,
    );

    // If user never heard it OR new broadcast exists => play once
    if (latest.createdAt > session.lastHeardBroadcastAt) {
      await SoundService.playAlert();
      return session.copyWith(lastHeardBroadcastAt: latest.createdAt);
    }

    return session;
  }
}
