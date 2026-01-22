import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/schedule_hive_model.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryApi implements ScheduleRepository {
  ScheduleRepositoryApi({
    required ApiClient client,
    required this.accessToken,
  }) : _client = client;

  final ApiClient _client;
  final String? accessToken;

  @override
  Future<List<ScheduleHiveModel>> getAll() async {
    final response = await _client.getJson(
      ApiEndpoints.schedules,
      accessToken: accessToken,
    );
    final items = _extractList(response);
    return items.map(ScheduleHiveModel.fromJson).toList();
  }

  @override
  Future<void> upsert(ScheduleHiveModel model) async {
    final payload = model.toJson()..remove('id');
    if (model.id.isEmpty) {
      await _client.postJson(
        ApiEndpoints.schedules,
        payload,
        accessToken: accessToken,
      );
      return;
    }

    await _client.patchJson(
      '${ApiEndpoints.schedules}/${model.id}',
      payload,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.deleteJson(
      '${ApiEndpoints.schedules}/$id',
      accessToken: accessToken,
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['schedules'] ?? response['items'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['schedules'] ?? data['items'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return [];
  }
}
