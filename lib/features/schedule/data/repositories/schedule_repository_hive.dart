import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';

import '../models/schedule_hive_model.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryHive implements ScheduleRepository {
  Box<ScheduleHiveModel> get _box =>
      HiveService.box<ScheduleHiveModel>(HiveTableConstant.schedulesBox);

  @override
  Future<List<ScheduleHiveModel>> getAll() async {
    final list = _box.values.toList();
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a.dateISO);
      final bDate = DateTime.tryParse(b.dateISO);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return list;
  }

  @override
  Future<void> upsert(ScheduleHiveModel model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> deleteById(String id) async {
    await _box.delete(id);
  }
}
