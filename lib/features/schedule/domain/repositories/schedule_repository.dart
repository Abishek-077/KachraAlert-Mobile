import '../../data/models/schedule_hive_model.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleHiveModel>> getAll();
  Future<void> upsert(ScheduleHiveModel model);
  Future<void> deleteById(String id);
}
