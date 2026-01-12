import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/features/reports/data/models/report_hive_model.dart';
import 'package:smart_waste_app/features/reports/data/repositories/report_repository_hive.dart';
import 'package:uuid/uuid.dart';

final reportRepoProvider = Provider((ref) => ReportRepositoryHive());

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<ReportHiveModel>>>(
      (ref) => ReportsNotifier(ref.watch(reportRepoProvider)),
    );

class ReportsNotifier extends StateNotifier<AsyncValue<List<ReportHiveModel>>> {
  ReportsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ReportRepositoryHive _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({
    required String userId,
    required String category,
    required String location,
    required String message,
  }) async {
    final report = ReportHiveModel(
      id: const Uuid().v4(),
      userId: userId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      category: category,
      location: location.trim(),
      message: message.trim(),
      status: 'pending', // Default status as per requirements
    );
    await _repo.upsert(report);
    await load();
  }

  Future<void> adminUpdateStatus(String id, String status) async {
    final allReports = state.valueOrNull ?? [];
    final report = allReports.firstWhere((r) => r.id == id);
    final updated = report.copyWith(status: status);
    await _repo.upsert(updated);
    await load();
  }

  Future<void> update(ReportHiveModel report) async {
    await _repo.upsert(report);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
