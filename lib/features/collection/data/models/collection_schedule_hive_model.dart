import 'package:hive/hive.dart';

part 'collection_schedule_hive_model.g.dart';

@HiveType(typeId: 3) // collectionScheduleTypeId
class CollectionScheduleHiveModel extends HiveObject {
  @HiveField(0)
  final String routeId;

  @HiveField(1)
  final String area;

  @HiveField(2)
  final String days; // e.g., "Monday, Thursday"

  @HiveField(3)
  final String time;

  @HiveField(4)
  final List<String> wasteTypes;

  CollectionScheduleHiveModel({
    required this.routeId,
    required this.area,
    required this.days,
    required this.time,
    required this.wasteTypes,
    required String dayOfWeek,
  });
}
