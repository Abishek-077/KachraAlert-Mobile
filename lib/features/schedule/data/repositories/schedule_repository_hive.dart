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
    list.sort((a, b) => a.dateMillis.compareTo(b.dateMillis));
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
