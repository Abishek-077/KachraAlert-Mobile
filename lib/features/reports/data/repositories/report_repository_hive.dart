import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';
import '../models/report_hive_model.dart';

class ReportRepositoryHive {
  Box<ReportHiveModel> get _box =>
      HiveService.box<ReportHiveModel>(HiveTableConstant.reportsBox);

  Future<List<ReportHiveModel>> getAll() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> upsert(ReportHiveModel report) async {
    await _box.put(report.id, report);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
