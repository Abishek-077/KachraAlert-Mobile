import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_alert_repository_api.dart';
import '../../data/models/admin_alert_hive_model.dart';

final adminAlertRepoProvider = Provider<AdminAlertRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return AdminAlertRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final adminAlertsProvider = StateNotifierProvider<AdminAlertsNotifier,
    AsyncValue<List<AdminAlertHiveModel>>>((ref) {
  return AdminAlertsNotifier(ref.watch(adminAlertRepoProvider));
});

class AdminAlertsNotifier
    extends StateNotifier<AsyncValue<List<AdminAlertHiveModel>>> {
  AdminAlertsNotifier(this._local) : super(const AsyncValue.loading()) {
    load();
  }

  final AdminAlertRepositoryApi _local;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _local.getAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({
    required String title,
    required String message,
  }) async {
    await _local.broadcast(title: title.trim(), message: message.trim());
    await load();
  }

  Future<void> update({
    required String id,
    required String title,
    required String message,
  }) async {
    await _local.broadcast(title: title.trim(), message: message.trim());
    await load();
  }

  Future<void> delete(String id) async {
    await load();
  }

  // Keep broadcast for backward compatibility
  Future<void> broadcast({
    required String title,
    required String message,
  }) async {
    await create(title: title, message: message);
  }

  Future<void> updateAlert(
      {required String id,
      required String title,
      required String message}) async {}
}
