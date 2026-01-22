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
    final token = _requireAccessToken();
    final response = await _client.getJson(
      ApiEndpoints.schedules,
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(ScheduleHiveModel.fromJson).toList();
  }

  @override
  Future<void> upsert(ScheduleHiveModel model) async {
    final token = _requireAccessToken();
    final payload = model.toJson()..remove('id');
    if (model.id.isEmpty) {
      await _client.postJson(
        ApiEndpoints.schedules,
        payload,
        accessToken: token,
      );
      return;
    }

    await _client.patchJson(
      '${ApiEndpoints.schedules}/${model.id}',
      payload,
      accessToken: token,
    );
  }

  @override
  Future<void> deleteById(String id) async {
    final token = _requireAccessToken();
    await _client.deleteJson(
      '${ApiEndpoints.schedules}/$id',
      accessToken: token,
    );
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to access schedules.');
    }
    return token;
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
