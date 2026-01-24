import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/admin_alert_hive_model.dart';

class AdminAlertRepositoryApi {
  AdminAlertRepositoryApi({required ApiClient client, required this.accessToken})
      : _client = client;

  final ApiClient _client;
  final String? accessToken;

  Future<List<AdminAlertHiveModel>> getAll() async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      ApiEndpoints.alerts,
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(AdminAlertHiveModel.fromJson).toList();
  }

  Future<AdminAlertHiveModel> broadcast({
    required String title,
    required String message,
  }) async {
    final token = _requireAccessToken();
    final response = await _client.postJson(
      ApiEndpoints.broadcastAlert,
      {
        'title': title,
        'body': message,
        'severity': 'info',
        'target': 'all',
      },
      accessToken: token,
    );
    final payload = _extractItem(response);
    return AdminAlertHiveModel.fromJson(payload);
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to access alerts.');
    }
    return token;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['alerts'] ?? response['items'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['alerts'] ?? data['items'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractItem(Map<String, dynamic> response) {
    final data = response['data'] ?? response['alert'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
