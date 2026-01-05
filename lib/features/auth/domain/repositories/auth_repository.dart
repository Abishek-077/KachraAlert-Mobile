// lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/auth_entity.dart';

abstract class AuthRepository {
  /// Register a new user
  Future<AuthEntity> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  });

  /// Login with email and password
  Future<AuthEntity?> login(String email, String password);

  /// Get current user by userId
  AuthEntity? getCurrentUser(String userId);

  /// Logout current user
  Future<void> logout();

  /// Check if email exists
  Future<bool> emailExists(String email);

  /// Delete user account
  Future<void> deleteUser(String userId);

  /// Update user information
  Future<AuthEntity> updateUser(AuthEntity user);
}
