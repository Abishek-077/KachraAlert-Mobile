import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';
import '../../models/admin_alert_hive_model.dart';

class AdminAlertLocalDataSource {
  final Box<AdminAlertHiveModel> _box = HiveService.box<AdminAlertHiveModel>(
    HiveTableConstant.adminAlertsBox,
  );

  Future<List<AdminAlertHiveModel>> getAll() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(AdminAlertHiveModel alert) async {
    await _box.put(alert.id, alert);
  }

  Future<void> update(AdminAlertHiveModel alert) async {
    await _box.put(alert.id, alert);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<AdminAlertHiveModel?> getById(String id) async {
    return _box.get(id);
  }
}
