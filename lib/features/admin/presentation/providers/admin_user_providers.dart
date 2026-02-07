import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_user_repository_api.dart';

final adminUsersLastSyncProvider = StateProvider<DateTime?>((ref) => null);

final adminUserRepoProvider = Provider<AdminUserRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return AdminUserRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUser>>>(
  (ref) => AdminUsersNotifier(ref, ref.watch(adminUserRepoProvider)),
);

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<AdminUser>>> {
  AdminUsersNotifier(this._ref, this._repo)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final AdminUserRepositoryApi _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getAll();
      state = AsyncValue.data(list);
      _ref.read(adminUsersLastSyncProvider.notifier).state = DateTime.now();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({
    required String accountType,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String society,
    required String building,
    required String apartment,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    await _repo.createUser(
      accountType: accountType,
      name: name,
      email: email,
      phone: phone,
      password: password,
      society: society,
      building: building,
      apartment: apartment,
      imageBytes: imageBytes,
      imageName: imageName,
    );
    await load();
  }

  Future<void> update({
    required String id,
    required String accountType,
    required String name,
    required String email,
    required String phone,
    String? password,
    required String society,
    required String building,
    required String apartment,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    await _repo.updateUser(
      id: id,
      accountType: accountType,
      name: name,
      email: email,
      phone: phone,
      password: password,
      society: society,
      building: building,
      apartment: apartment,
      imageBytes: imageBytes,
      imageName: imageName,
    );
    await load();
  }

  Future<void> updateStatus({
    required String id,
    bool? isBanned,
    double? lateFeePercent,
  }) async {
    await _repo.updateStatus(
      id: id,
      isBanned: isBanned,
      lateFeePercent: lateFeePercent,
    );
    await load();
  }

  Future<void> deleteUser(String id) async {
    await _repo.deleteUser(id);
    await load();
  }
}
