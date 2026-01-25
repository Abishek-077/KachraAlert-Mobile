import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/alert_local_datasource.dart';
import '../../data/models/alert_hive_model.dart';
import '../../domain/entities/alert_status.dart';

final alertLocalDataSourceProvider = Provider((ref) => AlertLocalDataSource());

final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, List<AlertHiveModel>>(
  AlertsNotifier.new,
);

class AlertsNotifier extends AsyncNotifier<List<AlertHiveModel>> {
  AlertLocalDataSource get _local => ref.watch(alertLocalDataSourceProvider);

  @override
  Future<List<AlertHiveModel>> build() async {
    return _fetchAlerts();
  }

  Future<List<AlertHiveModel>> _fetchAlerts() async {
    return _local.getAll();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final data = await _fetchAlerts();
    state = AsyncValue.data(data);
  }

  Future<void> createAlert({
    required String wasteType,
    required String note,
    required double lat,
    required double lng,
  }) async {
    final model = AlertHiveModel(
      id: const Uuid().v4(),
      wasteType: wasteType,
      note: note,
      lat: lat,
      lng: lng,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      status: AlertStatus.pending.name,
    );
    await _local.upsert(model);
    await load();
  }

  Future<void> setStatus(String id, AlertStatus status) async {
    await _local.updateStatus(id, status.name);
    await load();
  }

  void delete(String alertId) {}
}
