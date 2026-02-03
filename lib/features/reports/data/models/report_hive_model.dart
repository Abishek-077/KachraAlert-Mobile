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

  @HiveField(7)
  final String? attachmentUrl;

  @HiveField(8)
  final String? reporterName;

  @HiveField(9)
  final String? reporterPhotoUrl;

  ReportHiveModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.category,
    required this.location,
    required this.message,
    required this.status,
    this.attachmentUrl,
    this.reporterName,
    this.reporterPhotoUrl,
  });

  factory ReportHiveModel.fromJson(Map<String, dynamic> json) {
    final reporter = json['user'] ??
        json['createdBy'] ??
        json['reporter'] ??
        json['author'];
    final reporterMap = reporter is Map ? reporter.cast<String, dynamic>() : null;
    final reporterName = _nullableString(
      json['userName'] ??
          json['createdByName'] ??
          json['reporterName'] ??
          reporterMap?['fullName'] ??
          reporterMap?['name'] ??
          reporterMap?['email'],
    );
    final reporterPhotoUrl = _nullableString(
      json['userPhotoUrl'] ??
          json['createdByPhotoUrl'] ??
          json['reporterPhotoUrl'] ??
          reporterMap?['profilePhotoUrl'] ??
          reporterMap?['photoUrl'] ??
          reporterMap?['avatar'] ??
          reporterMap?['photo'],
    );

    return ReportHiveModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? json['createdBy'] ?? '').toString(),
      createdAt: _parseCreatedAt(json['createdAt']),
      category: (json['category'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      message:
          (json['message'] ?? json['note'] ?? json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      attachmentUrl: _nullableString(json['attachmentUrl'] ?? json['attachment']),
      reporterName: reporterName,
      reporterPhotoUrl: reporterPhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt,
      'category': category,
      'location': location,
      'message': message,
      'status': status,
      'attachmentUrl': attachmentUrl,
      'reporterName': reporterName,
      'reporterPhotoUrl': reporterPhotoUrl,
    };
  }

  ReportHiveModel copyWith({
    String? category,
    String? location,
    String? message,
    String? status,
    String? attachmentUrl,
    String? reporterName,
    String? reporterPhotoUrl,
  }) {
    return ReportHiveModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      category: category ?? this.category,
      location: location ?? this.location,
      message: message ?? this.message,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      reporterName: reporterName ?? this.reporterName,
      reporterPhotoUrl: reporterPhotoUrl ?? this.reporterPhotoUrl,
    );
  }
}

int _parseCreatedAt(dynamic value) {
  if (value == null) return DateTime.now().millisecondsSinceEpoch;
  if (value is int) return value;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.millisecondsSinceEpoch;
  }
  return DateTime.now().millisecondsSinceEpoch;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
