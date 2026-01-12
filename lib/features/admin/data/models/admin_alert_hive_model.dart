import 'package:hive/hive.dart';

part 'admin_alert_hive_model.g.dart';

@HiveType(typeId: 14)
class AdminAlertHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String message;

  @HiveField(3)
  final int createdAt;

  @HiveField(4)
  final int updatedAt; // epoch millis

  AdminAlertHiveModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  AdminAlertHiveModel copyWith({
    String? id,
    String? title,
    String? message,
    int? createdAt,
    int? updatedAt,
  }) {
    return AdminAlertHiveModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
