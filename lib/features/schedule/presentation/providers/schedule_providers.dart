import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_client.dart';
import '../../data/models/schedule_hive_model.dart';
import '../../data/repositories/schedule_repository_api.dart';
import '../../domain/repositories/schedule_repository.dart';

final scheduleRepoProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryApi(client: ref.watch(apiClientProvider));
});

final schedulesProvider = StateNotifierProvider<
    SchedulesNotifier, AsyncValue<List<ScheduleHiveModel>>>(
  (ref) => SchedulesNotifier(ref.watch(scheduleRepoProvider)),
);

class SchedulesNotifier extends StateNotifier<AsyncValue<List<ScheduleHiveModel>>> {
  SchedulesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ScheduleRepository _repo;
  static const _uuid = Uuid();

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
    required String area,
    required String shift,
    required String note,
  }) async {
    final model = ScheduleHiveModel(
      id: _uuid.v4(),
      dateMillis: DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
      area: area.trim(),
      note: note.trim(),
      shift: shift.trim(),
      isActive: true,
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
