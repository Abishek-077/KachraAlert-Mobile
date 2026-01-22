import 'package:hive/hive.dart';

part 'user_session_hive_model.g.dart';

@HiveType(typeId: 11)
class UserSessionHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String role; // resident | admin_driver

  @HiveField(3)
  final int lastHeardBroadcastAt; // epoch millis

  @HiveField(4)
  final String accessToken;

  UserSessionHiveModel({
    required this.userId,
    required this.email,
    this.role = 'resident',
    this.lastHeardBroadcastAt = 0,
    this.accessToken = '',
  });

  /// ✅ REQUIRED (fixes your error)
  UserSessionHiveModel copyWith({
    String? userId,
    String? email,
    String? role,
    int? lastHeardBroadcastAt,
    String? accessToken,
  }) {
    return UserSessionHiveModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      lastHeardBroadcastAt: lastHeardBroadcastAt ?? this.lastHeardBroadcastAt,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  bool get isAdmin => role == 'admin_driver';
}
