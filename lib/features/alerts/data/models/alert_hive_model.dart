import 'package:hive/hive.dart';

part 'alert_hive_model.g.dart';

@HiveType(typeId: 12)
class AlertHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String wasteType;

  @HiveField(2)
  final String note;

  @HiveField(3)
  final double lat;

  @HiveField(4)
  final double lng;

  @HiveField(5)
  final int createdAt;

  @HiveField(6)
  final String status;

  AlertHiveModel({
    required this.id,
    required this.wasteType,
    required this.note,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.status,
  });

  AlertHiveModel copyWith({String? status}) {
    return AlertHiveModel(
      id: id,
      wasteType: wasteType,
      note: note,
      lat: lat,
      lng: lng,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
