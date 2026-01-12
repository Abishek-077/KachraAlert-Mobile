import 'package:hive/hive.dart';

part 'schedule_hive_model.g.dart';

@HiveType(typeId: 21)
class ScheduleHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int dateMillis; // collection day

  @HiveField(2)
  final String area; // e.g. Ward 10 / Baneshwor

  @HiveField(3)
  final String note; // admin message

  @HiveField(4)
  final String shift; // Morning/Evening

  @HiveField(5)
  final bool isActive;

  ScheduleHiveModel({
    required this.id,
    required this.dateMillis,
    required this.area,
    required this.note,
    required this.shift,
    required this.isActive,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);

  ScheduleHiveModel copyWith({
    String? id,
    int? dateMillis,
    String? area,
    String? note,
    String? shift,
    bool? isActive,
  }) {
    return ScheduleHiveModel(
      id: id ?? this.id,
      dateMillis: dateMillis ?? this.dateMillis,
      area: area ?? this.area,
      note: note ?? this.note,
      shift: shift ?? this.shift,
      isActive: isActive ?? this.isActive,
    );
  }
}
