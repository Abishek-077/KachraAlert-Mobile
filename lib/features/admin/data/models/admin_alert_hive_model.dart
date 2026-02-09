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

  @HiveField(5)
  final String? adminName;

  @HiveField(6)
  final String? adminPhotoUrl;

  AdminAlertHiveModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.adminName,
    this.adminPhotoUrl,
  });

  factory AdminAlertHiveModel.fromJson(Map<String, dynamic> json) {
    return AdminAlertHiveModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['body'] ?? json['message'] ?? '').toString(),
      createdAt: _parseCreatedAt(json['createdAt']),
      updatedAt: _parseCreatedAt(json['updatedAt'] ?? json['createdAt']),
      adminName: _extractAdminName(json),
      adminPhotoUrl: _extractAdminPhotoUrl(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'adminName': adminName,
      'adminPhotoUrl': adminPhotoUrl,
    };
  }

  AdminAlertHiveModel copyWith({
    String? id,
    String? title,
    String? message,
    int? createdAt,
    int? updatedAt,
    String? adminName,
    String? adminPhotoUrl,
  }) {
    return AdminAlertHiveModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminName: adminName ?? this.adminName,
      adminPhotoUrl: adminPhotoUrl ?? this.adminPhotoUrl,
    );
  }
}

String? _extractAdminName(Map<String, dynamic> json) {
  final direct = _firstNonEmptyString([
    json['adminName'],
    json['senderName'],
    json['authorName'],
    json['createdByName'],
    json['issuedByName'],
    json['sourceName'],
    json['publishedBy'],
  ]);
  if (direct != null) return direct;

  for (final key in ['admin', 'sender', 'author', 'createdBy', 'issuedBy']) {
    final nested = _mapValue(json[key]);
    if (nested == null) continue;
    final nestedName = _firstNonEmptyString([
      nested['name'],
      nested['fullName'],
      nested['displayName'],
      nested['username'],
    ]);
    if (nestedName != null) return nestedName;
  }
  return null;
}

String? _extractAdminPhotoUrl(Map<String, dynamic> json) {
  final direct = _firstNonEmptyString([
    json['adminPhotoUrl'],
    json['adminProfilePhotoUrl'],
    json['adminProfileImageUrl'],
    json['profilePhotoUrl'],
    json['profileImageUrl'],
    json['senderPhotoUrl'],
    json['senderProfilePhotoUrl'],
    json['authorPhotoUrl'],
    json['avatar'],
    json['avatarUrl'],
    json['imageUrl'],
  ]);
  if (direct != null) return direct;

  for (final key in ['admin', 'sender', 'author', 'createdBy', 'issuedBy']) {
    final nested = _mapValue(json[key]);
    if (nested == null) continue;
    final nestedPhoto = _firstNonEmptyString([
      nested['profilePhotoUrl'],
      nested['profileImageUrl'],
      nested['avatar'],
      nested['avatarUrl'],
      nested['photoUrl'],
      nested['imageUrl'],
    ]);
    if (nestedPhoto != null) return nestedPhoto;
  }
  return null;
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final value in candidates) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return null;
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
