import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/schedule_hive_model.dart';
import '../../data/repositories/schedule_repository_api.dart';
import '../../domain/repositories/schedule_repository.dart';

final scheduleRepoProvider = Provider<ScheduleRepository>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return ScheduleRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final schedulesProvider = StateNotifierProvider<SchedulesNotifier,
    AsyncValue<List<ScheduleHiveModel>>>(
  (ref) => SchedulesNotifier(ref.watch(scheduleRepoProvider)),
);

class SchedulesNotifier
    extends StateNotifier<AsyncValue<List<ScheduleHiveModel>>> {
  SchedulesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ScheduleRepository _repo;

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

  Future<void> updateSchedule(ScheduleHiveModel copyWith) async {}
}
