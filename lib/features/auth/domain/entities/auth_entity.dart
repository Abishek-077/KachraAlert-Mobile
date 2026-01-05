// lib/features/auth/domain/entities/auth_entity.dart

class AuthEntity {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String role;
  final DateTime joinedDate;

  AuthEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.role = 'citizen',
    required this.joinedDate,
  });

  @override
  String toString() {
    return 'AuthEntity(userId: $userId, fullName: $fullName, email: $email, phone: $phone, address: $address, role: $role, joinedDate: $joinedDate)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          fullName == other.fullName &&
          email == other.email &&
          phone == other.phone &&
          address == other.address &&
          role == other.role &&
          joinedDate == other.joinedDate;

  @override
  int get hashCode =>
      userId.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      role.hashCode ^
      joinedDate.hashCode;

  AuthEntity copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? role,
    DateTime? joinedDate,
  }) {
    return AuthEntity(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}
