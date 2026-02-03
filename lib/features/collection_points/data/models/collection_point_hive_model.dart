import 'package:hive/hive.dart';

part 'collection_point_hive_model.g.dart';

@HiveType(typeId: 41)
class CollectionPointHiveModel extends HiveObject {
  CollectionPointHiveModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final int createdAt;

  CollectionPointHiveModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? createdAt,
  }) {
    return CollectionPointHiveModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
