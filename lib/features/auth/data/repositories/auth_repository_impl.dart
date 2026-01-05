// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kachra_alert/features/auth/data/datasources/local/auth_local_datasource.dart';

import 'package:kachra_alert/features/auth/data/models/user_hive_model.dart';
import 'package:kachra_alert/features/auth/domain/entities/auth_entity.dart';
import 'package:kachra_alert/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDatasource = ref.read(authLocalDatasourceProvider);
  return AuthRepositoryImpl(localDatasource);
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<AuthEntity> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final exists = await emailExists(email);
    if (exists) {
      throw Exception('Email already registered');
    }

    final userModel = UserHiveModel(
      userId: '', // Will be auto-generated
      fullName: fullName,
      email: email.trim(),
      password: password, // TODO: Hash in production!
      phone: phone,
      address: address,
      joinedDate: DateTime.now(),
    );

    final savedUser = await _datasource.register(userModel);
    return savedUser.toEntity();
  }

  @override
  Future<AuthEntity?> login(String email, String password) async {
    final userModel = await _datasource.login(email.trim(), password);
    return userModel?.toEntity();
  }

  @override
  AuthEntity? getCurrentUser(String userId) {
    final userModel = _datasource.getUserById(userId);
    return userModel?.toEntity();
  }

  @override
  Future<void> logout() async {
    // Local logout: nothing to clear in Hive
    // Session handling (current user ID) should be done separately
    return;
  }

  @override
  Future<bool> emailExists(String email) async {
    return await _datasource.emailExists(email.trim());
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _datasource.deleteUser(userId);
  }

  @override
  Future<AuthEntity> updateUser(AuthEntity user) async {
    // Fetch existing user to preserve password
    final existingModel = _datasource.getUserById(user.userId);
    if (existingModel == null) {
      throw Exception('User not found');
    }

    final updatedModel = existingModel.copyWith(
      fullName: user.fullName,
      phone: user.phone,
      address: user.address,
      // email and role could be updated if needed
    );

    await _datasource.updateUser(updatedModel);
    return updatedModel.toEntity();
  }
}
