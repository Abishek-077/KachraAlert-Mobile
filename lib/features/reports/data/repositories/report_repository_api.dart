import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/report_hive_model.dart';

class ReportRepositoryApi {
  ReportRepositoryApi({required ApiClient client, required this.accessToken})
      : _client = client;

  final ApiClient _client;
  final String? accessToken;

  Future<List<ReportHiveModel>> getAll() async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      ApiEndpoints.reports,
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(_mapReport).toList();
  }

  Future<ReportHiveModel> create({
    required String category,
    required String location,
    required String message,
  }) async {
    final token = _requireAccessToken();
    final title = _buildTitle(category: category, location: location, message: message);
    final response = await _client.postJson(
      ApiEndpoints.reports,
      {
        'title': title,
        'category': _mapCategoryToApi(category),
        'priority': 'Medium',
      },
      accessToken: token,
    );
    final payload = _extractItem(response);
    final report = _mapReport(payload, fallbackTitle: title);
    return report.copyWith(
      location: location,
      message: message,
    );
  }

  Future<void> delete(String id) async {
    final token = _requireAccessToken();
    await _client.deleteJson(
      '${ApiEndpoints.reports}/$id',
      accessToken: token,
    );
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to access reports.');
    }
    return token;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['reports'] ?? response['items'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['reports'] ?? data['items'];
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
    final data = response['data'] ?? response['report'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  ReportHiveModel _mapReport(
    Map<String, dynamic> json, {
    String? fallbackTitle,
  }) {
    final mapped = ReportHiveModel.fromJson(json);
    final normalizedStatus = _normalizeStatus(mapped.status);
    final title = (json['title'] ?? fallbackTitle ?? '').toString();
    final location = mapped.location.isNotEmpty ? mapped.location : title;
    final message = mapped.message.isNotEmpty ? mapped.message : title;

    return ReportHiveModel(
      id: mapped.id,
      userId: mapped.userId,
      createdAt: mapped.createdAt,
      category: _mapCategoryFromApi(mapped.category),
      location: location,
      message: message,
      status: normalizedStatus,
    );
  }

  String _normalizeStatus(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('progress')) return 'in_progress';
    if (value.contains('resolved') || value.contains('closed')) return 'resolved';
    return 'pending';
  }

  String _mapCategoryToApi(String category) {
    switch (category) {
      case 'Overflowing Bin':
        return 'Overflow';
      case 'Bad Smell':
        return 'Other';
      default:
        return category;
    }
  }

  String _mapCategoryFromApi(String category) {
    switch (category) {
      case 'Overflow':
        return 'Overflowing Bin';
      default:
        return category;
    }
  }

  String _buildTitle({
    required String category,
    required String location,
    required String message,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.length >= 6) return trimmedMessage;
    final trimmedLocation = location.trim();
    if (trimmedLocation.isNotEmpty) {
      return '$category @ $trimmedLocation';
    }
    return category;
  }
}
