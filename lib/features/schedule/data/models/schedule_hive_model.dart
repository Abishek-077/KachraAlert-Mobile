import 'package:hive/hive.dart';

part 'schedule_hive_model.g.dart';

@HiveType(typeId: 21)
class ScheduleHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String dateISO; // ISO date string

  @HiveField(2)
  final String timeLabel; // Morning/Evening

  @HiveField(3)
  final String waste; // Biodegradable/Dry Waste/etc

  @HiveField(4)
  final String status; // Upcoming/Completed/Missed

  ScheduleHiveModel({
    required this.id,
    required this.dateISO,
    required this.timeLabel,
    required this.waste,
    required this.status,
  });

  DateTime? get date => DateTime.tryParse(dateISO);

  factory ScheduleHiveModel.fromJson(Map<String, dynamic> json) {
    return ScheduleHiveModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      dateISO:
          (json['dateISO'] ?? json['date'] ?? json['collectionDate'] ?? '')
              .toString(),
      timeLabel: (json['timeLabel'] ?? json['time'] ?? '').toString(),
      waste: (json['waste'] ?? json['wasteType'] ?? '').toString(),
      status: (json['status'] ?? 'Upcoming').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateISO': dateISO,
      'timeLabel': timeLabel,
      'waste': waste,
      'status': status,
    };
  }

  ScheduleHiveModel copyWith({
    String? id,
    String? dateISO,
    String? timeLabel,
    String? waste,
    String? status,
  }) {
    return ScheduleHiveModel(
      id: id ?? this.id,
      dateISO: dateISO ?? this.dateISO,
      timeLabel: timeLabel ?? this.timeLabel,
      waste: waste ?? this.waste,
      status: status ?? this.status,
    );
  }
}
