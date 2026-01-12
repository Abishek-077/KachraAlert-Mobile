import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/admin_alert_local_datasource.dart';
import '../../data/models/admin_alert_hive_model.dart';

final adminAlertLocalProvider = Provider((ref) => AdminAlertLocalDataSource());

final adminAlertsProvider =
    StateNotifierProvider<
      AdminAlertsNotifier,
      AsyncValue<List<AdminAlertHiveModel>>
    >((ref) {
      return AdminAlertsNotifier(ref.watch(adminAlertLocalProvider));
    });

class AdminAlertsNotifier
    extends StateNotifier<AsyncValue<List<AdminAlertHiveModel>>> {
  AdminAlertsNotifier(this._local) : super(const AsyncValue.loading()) {
    load();
  }

  final AdminAlertLocalDataSource _local;

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
    final now = DateTime.now().millisecondsSinceEpoch;
    final alert = AdminAlertHiveModel(
      id: const Uuid().v4(),
      title: title.trim(),
      message: message.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _local.add(alert);
    await load();
  }

  Future<void> update({
    required String id,
    required String title,
    required String message,
  }) async {
    final existing = await _local.getById(id);
    if (existing == null) return;
    
    final updated = existing.copyWith(
      title: title.trim(),
      message: message.trim(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _local.update(updated);
    await load();
  }

  Future<void> delete(String id) async {
    await _local.delete(id);
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
