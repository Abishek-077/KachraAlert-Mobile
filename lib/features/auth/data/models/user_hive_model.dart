// lib/features/auth/data/models/user_hive_model.dart

import 'package:hive/hive.dart';
import 'package:kachra_alert/core/constants/hive_table_constant.dart';
import 'package:kachra_alert/features/auth/domain/entities/auth_entity.dart';

part 'user_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.userTypeId)
class UserHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String phone;

  @HiveField(5)
  final String address;

  @HiveField(6)
  final String role;

  @HiveField(7)
  final DateTime joinedDate;

  UserHiveModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    this.role = 'citizen',
    required this.joinedDate,
  });

  /// Factory constructor to create UserHiveModel from AuthEntity
  /// Requires password as a separate parameter for security
  factory UserHiveModel.fromEntity(AuthEntity entity, String password) {
    return UserHiveModel(
      userId: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      password: password,
      phone: entity.phone,
      address: entity.address,
      role: entity.role,
      joinedDate: entity.joinedDate,
    );
  }

  /// Convert to domain entity (password is NOT included)
  /// This ensures sensitive data doesn't leak into the domain layer
  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      role: role,
      joinedDate: joinedDate,
    );
  }

  /// Copy with method for creating modified instances
  UserHiveModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? password,
    String? phone,
    String? address,
    String? role,
    DateTime? joinedDate,
  }) {
    return UserHiveModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  @override
  String toString() {
    return 'UserHiveModel(userId: $userId, fullName: $fullName, email: $email, phone: $phone, address: $address, role: $role, joinedDate: $joinedDate)';
  }
}
