import 'package:hive/hive.dart';
import 'package:smart_waste_app/core/constants/hive_table_constant.dart';
import 'package:smart_waste_app/core/services/hive/hive_service.dart';

import '../../domain/repositories/collection_point_repository.dart';
import '../models/collection_point_hive_model.dart';

class CollectionPointRepositoryHive implements CollectionPointRepository {
  Box<CollectionPointHiveModel> get _box =>
      HiveService.box<CollectionPointHiveModel>(
        HiveTableConstant.collectionPointsBox,
      );

  @override
  Future<List<CollectionPointHiveModel>> getAll() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> upsert(CollectionPointHiveModel model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> deleteById(String id) async {
    await _box.delete(id);
  }
}
