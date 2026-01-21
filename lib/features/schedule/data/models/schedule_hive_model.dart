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

  factory ScheduleHiveModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['dateMillis'] ?? json['date'] ?? json['collectionDate'];
    final parsedDate = _parseDateMillis(rawDate);

    return ScheduleHiveModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      dateMillis: parsedDate ??
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      area: (json['area'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      shift: (json['shift'] ?? '').toString(),
      isActive: json['isActive'] == null ? true : json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateMillis': dateMillis,
      'date': date.toIso8601String(),
      'area': area,
      'note': note,
      'shift': shift,
      'isActive': isActive,
    };
  }

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

  static int? _parseDateMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.millisecondsSinceEpoch;
    }
    return null;
  }
}
