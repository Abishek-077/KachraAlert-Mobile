// lib/features/auth/data/datasources/auth_local_datasource.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kachra_alert/core/services/hive/hive_service.dart';
import 'package:kachra_alert/features/auth/data/models/user_hive_model.dart';
import 'package:uuid/uuid.dart';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return AuthLocalDatasource(hiveService);
});

class AuthLocalDatasource {
  final HiveService _hiveService;

  AuthLocalDatasource(this._hiveService);

  Future<UserHiveModel> register(UserHiveModel user) async {
    final userToSave = user.userId.isEmpty
        ? user.copyWith(userId: const Uuid().v4())
        : user;

    await _hiveService.userBox.put(userToSave.userId, userToSave);
    return userToSave;
  }

  Future<UserHiveModel?> login(String email, String password) async {
    try {
      final matchingUsers = _hiveService.userBox.values
          .where(
            (u) =>
                u.email.toLowerCase() == email.trim().toLowerCase() &&
                u.password == password,
          )
          .toList();

      return matchingUsers.isNotEmpty ? matchingUsers.first : null;
    } catch (e) {
      return null;
    }
  }

  UserHiveModel? getUserById(String userId) {
    return _hiveService.userBox.get(userId);
  }

  Future<bool> emailExists(String email) async {
    return _hiveService.userBox.values.any(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
  }

  Future<void> updateUser(UserHiveModel updatedUser) async {
    await _hiveService.userBox.put(updatedUser.userId, updatedUser);
  }

  Future<void> deleteUser(String userId) async {
    await _hiveService.userBox.delete(userId);
  }
}
