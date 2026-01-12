import 'package:hive_flutter/hive_flutter.dart';

import '../../constants/hive_table_constant.dart';

import '../../../features/auth/data/models/user_session_hive_model.dart';
import '../../../features/auth/data/models/user_account_hive_model.dart';
import '../../../features/alerts/data/models/alert_hive_model.dart';
import '../../../features/admin/data/models/admin_alert_hive_model.dart';
import '../../../features/schedule/data/models/schedule_hive_model.dart';
import '../../../features/reports/data/models/report_hive_model.dart';

class HiveService {
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static Future<void> init() {
    _initFuture ??= _initInternal();
    return _initFuture!;
  }

  static Future<void> _initInternal() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // ✅ Register adapters (ONLY for boxes that store models)
    _registerAdapter<UserSessionHiveModel>(11, UserSessionHiveModelAdapter());
    _registerAdapter<AlertHiveModel>(12, AlertHiveModelAdapter());
    _registerAdapter<UserAccountHiveModel>(13, UserAccountHiveModelAdapter());
    _registerAdapter<AdminAlertHiveModel>(14, AdminAlertHiveModelAdapter());
    _registerAdapter<ScheduleHiveModel>(21, ScheduleHiveModelAdapter());
    _registerAdapter<ReportHiveModel>(31, ReportHiveModelAdapter());

    // ✅ Open settings_box as untyped Box (because you store bools/strings)
    await _openUntypedBox(HiveTableConstant.settingsBox);

    // ✅ Open other boxes typed
    await _openTypedBox<UserSessionHiveModel>(HiveTableConstant.sessionBox);
    await _openTypedBox<AlertHiveModel>(HiveTableConstant.alertsBox);
    await _openTypedBox<UserAccountHiveModel>(HiveTableConstant.accountsBox);
    await _openTypedBox<AdminAlertHiveModel>(HiveTableConstant.adminAlertsBox);
    await _openTypedBox<ScheduleHiveModel>(HiveTableConstant.schedulesBox);
    await _openTypedBox<ReportHiveModel>(HiveTableConstant.reportsBox);

    _initialized = true;
  }

  static void _registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  static Future<Box> _openUntypedBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    try {
      return await Hive.openBox(name);
    } on HiveError {
      if (Hive.isBoxOpen(name)) return Hive.box(name);
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox(name);
    }
  }

  static Future<Box<T>> _openTypedBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    try {
      return await Hive.openBox<T>(name);
    } on HiveError {
      if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  // ✅ Use this for settings_box (dynamic)
  static Box untypedBox(String name) => Hive.box(name);

  // ✅ Use this for typed model boxes
  static Box<T> box<T>(String name) => Hive.box<T>(name);

  static Future<void> closeAll() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
    _initFuture = null;
  }
}
