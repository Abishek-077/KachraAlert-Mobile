import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/features/reports/data/models/report_hive_model.dart';
import 'package:smart_waste_app/features/reports/data/repositories/report_repository_api.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final reportRepoProvider = Provider<ReportRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return ReportRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<ReportHiveModel>>>(
      (ref) => ReportsNotifier(ref.watch(reportRepoProvider)),
    );

class ReportsNotifier extends StateNotifier<AsyncValue<List<ReportHiveModel>>> {
  ReportsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ReportRepositoryApi _repo;

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
    await _repo.create(
      category: category,
      location: location.trim(),
      message: message.trim(),
    );
    await load();
  }

  Future<void> adminUpdateStatus(String id, String status) async {
    final allReports = state.valueOrNull ?? [];
    final report = allReports.firstWhere((r) => r.id == id);
    final updated = report.copyWith(status: status);
    await _repo.delete(report.id);
    await _repo.create(
      category: updated.category,
      location: updated.location,
      message: updated.message,
    );
    await load();
  }

  Future<void> update(ReportHiveModel report) async {
    await _repo.delete(report.id);
    await _repo.create(
      category: report.category,
      location: report.location,
      message: report.message,
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
