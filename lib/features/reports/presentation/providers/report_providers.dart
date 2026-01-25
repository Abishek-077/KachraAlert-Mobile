import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/features/reports/data/models/report_hive_model.dart';
import 'package:smart_waste_app/features/reports/data/repositories/report_repository_api.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

final reportRepoProvider = Provider<ReportRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return ReportRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final reportsProvider =
    AsyncNotifierProvider<ReportsNotifier, List<ReportHiveModel>>(
  ReportsNotifier.new,
);

class ReportsNotifier extends AsyncNotifier<List<ReportHiveModel>> {
  ReportRepositoryApi get _repo => ref.watch(reportRepoProvider);

  @override
  Future<List<ReportHiveModel>> build() async {
    return _fetchReports();
  }

  Future<List<ReportHiveModel>> _fetchReports() async {
    return _repo.getAll();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchReports();
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
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    await _repo.create(
      category: category,
      location: location.trim(),
      message: message.trim(),
      attachmentBytes: attachmentBytes,
      attachmentName: attachmentName,
    );
    await load();
  }

  Future<void> adminUpdateStatus(String id, String status) async {
    final allReports = state.valueOrNull ?? [];
    final report = _findById(allReports, id);
    if (report == null) return;
    await _repo.updateStatus(id: report.id, status: status);
    await load();
  }

  Future<void> updateReport(ReportHiveModel report) async {
    await _repo.update(
      id: report.id,
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

  ReportHiveModel? _findById(List<ReportHiveModel> reports, String id) {
    for (final report in reports) {
      if (report.id == id) {
        return report;
      }
    }
    return null;
  }
}
