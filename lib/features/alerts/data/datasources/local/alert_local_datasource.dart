import 'package:hive/hive.dart';
import 'package:smart_waste_app/features/alerts/data/models/alert_hive_model.dart';
import '../../../../../core/constants/hive_table_constant.dart';
import '../../../../../core/services/hive/hive_service.dart';

class AlertLocalDataSource {
  final Box<AlertHiveModel> _box = HiveService.box<AlertHiveModel>(
    HiveTableConstant.alertsBox,
  );

  Future<List<AlertHiveModel>> getAll() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> upsert(AlertHiveModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> updateStatus(String id, String status) async {
    final old = _box.get(id);
    if (old == null) return;
    await _box.put(id, old.copyWith(status: status));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
