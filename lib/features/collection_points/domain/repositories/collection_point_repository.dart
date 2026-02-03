import '../../data/models/collection_point_hive_model.dart';

abstract class CollectionPointRepository {
  Future<List<CollectionPointHiveModel>> getAll();
  Future<void> upsert(CollectionPointHiveModel model);
  Future<void> deleteById(String id);
}
