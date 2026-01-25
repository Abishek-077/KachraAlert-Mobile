import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/schedule_hive_model.dart';
import '../../data/repositories/schedule_repository_api.dart';
import '../../domain/repositories/schedule_repository.dart';

final scheduleRepoProvider = Provider<ScheduleRepository>((ref) {
  final auth = ref.watch(authStateProvider).asData?.value;
  return ScheduleRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final schedulesProvider =
    AsyncNotifierProvider<SchedulesNotifier, List<ScheduleHiveModel>>(
  SchedulesNotifier.new,
);

class SchedulesNotifier extends AsyncNotifier<List<ScheduleHiveModel>> {
  ScheduleRepository get _repo => ref.watch(scheduleRepoProvider);

  @override
  Future<List<ScheduleHiveModel>> build() async {
    return _fetchSchedules();
  }

  Future<List<ScheduleHiveModel>> _fetchSchedules() async {
    return _repo.getAll();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchSchedules();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({
    required DateTime date,
    required String timeLabel,
    required String waste,
    required String status,
  }) async {
    final model = ScheduleHiveModel(
      id: '',
      dateISO: DateTime(date.year, date.month, date.day).toIso8601String(),
      timeLabel: timeLabel.trim(),
      waste: waste.trim(),
      status: status.trim(),
    );

    await _repo.upsert(model);
    await load();
  }

  Future<void> update(ScheduleHiveModel model) async {
    await _repo.upsert(model);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteById(id);
    await load();
  }
}
