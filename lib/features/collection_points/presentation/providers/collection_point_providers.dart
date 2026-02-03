import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/collection_point_hive_model.dart';
import '../../data/repositories/collection_point_repository_hive.dart';
import '../../domain/repositories/collection_point_repository.dart';

final collectionPointRepoProvider = Provider<CollectionPointRepository>((ref) {
  return CollectionPointRepositoryHive();
});

final collectionPointsProvider = StateNotifierProvider<
    CollectionPointsNotifier, AsyncValue<List<CollectionPointHiveModel>>>(
  (ref) => CollectionPointsNotifier(ref.watch(collectionPointRepoProvider)),
);

class CollectionPointsNotifier
    extends StateNotifier<AsyncValue<List<CollectionPointHiveModel>>> {
  CollectionPointsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final CollectionPointRepository _repo;
  final _uuid = const Uuid();

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
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final model = CollectionPointHiveModel(
      id: _uuid.v4(),
      name: name.trim(),
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.upsert(model);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteById(id);
    await load();
  }
}
