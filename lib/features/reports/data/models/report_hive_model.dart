import 'package:hive/hive.dart';

part 'report_hive_model.g.dart';

@HiveType(typeId: 31)
class ReportHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId; // who created it

  @HiveField(2)
  final int createdAt; // millis

  @HiveField(3)
  final String category; // Missed Pickup / Overflow / Other

  @HiveField(4)
  final String location;

  @HiveField(5)
  final String message;

  @HiveField(6)
  final String status; // pending | in_progress | resolved

  ReportHiveModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.category,
    required this.location,
    required this.message,
    required this.status,
  });

  ReportHiveModel copyWith({
    String? category,
    String? location,
    String? message,
    String? status,
  }) {
    return ReportHiveModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      category: category ?? this.category,
      location: location ?? this.location,
      message: message ?? this.message,
      status: status ?? this.status,
    );
  }
}
