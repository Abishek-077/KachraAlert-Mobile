import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_alert_repository_api.dart';
import '../../data/models/admin_alert_hive_model.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

final adminAlertRepoProvider = Provider<AdminAlertRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return AdminAlertRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final adminAlertsProvider =
    AsyncNotifierProvider<AdminAlertsNotifier, List<AdminAlertHiveModel>>(
  AdminAlertsNotifier.new,
);

class AdminAlertsNotifier extends AsyncNotifier<List<AdminAlertHiveModel>> {
  AdminAlertRepositoryApi get _local => ref.watch(adminAlertRepoProvider);

  @override
  Future<List<AdminAlertHiveModel>> build() async {
    return _fetchAlerts();
  }

  Future<List<AdminAlertHiveModel>> _fetchAlerts() async {
    return _local.getAll();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchAlerts();
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

  Future<void> updateAlert({
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
}
