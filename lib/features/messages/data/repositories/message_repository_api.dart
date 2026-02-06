import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/chat_contact.dart';
import '../models/chat_message.dart';

class MessageRepositoryApi {
  MessageRepositoryApi({
    required ApiClient client,
    required this.accessToken,
  }) : _client = client;

  final ApiClient _client;
  final String? accessToken;

  Future<List<ChatContact>> getContacts({
    int? limit,
    String? query,
  }) async {
    final token = _requireAccessToken();
    final params = <String, String>{};
    if (limit != null && limit > 0) {
      params['limit'] = limit.toString();
    }
    final trimmedQuery = query?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      params['query'] = trimmedQuery;
    }
    final queryString =
        params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final response = await _client.getJson(
      '${ApiEndpoints.messages}/contacts$queryString',
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(ChatContact.fromJson).toList();
  }

  Future<List<ChatMessage>> getConversation(
    String contactId, {
    int? limit,
    DateTime? before,
  }) async {
    final token = _requireAccessToken();
    final query = <String, String>{};
    if (limit != null && limit > 0) {
      query['limit'] = limit.toString();
    }
    if (before != null) {
      query['before'] = before.toIso8601String();
    }
    final queryString =
        query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final response = await _client.getJson(
      '${ApiEndpoints.messages}/${Uri.encodeComponent(contactId)}$queryString',
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendMessage({
    required String contactId,
    required String body,
  }) async {
    final token = _requireAccessToken();
    final response = await _client.postJson(
      '${ApiEndpoints.messages}/${Uri.encodeComponent(contactId)}',
      {'body': body.trim()},
      accessToken: token,
    );
    final data = _extractItem(response);
    return ChatMessage.fromJson(data);
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to access messaging.');
    }
    return token;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['messages'] ?? response['contacts'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['items'] ?? data['messages'] ?? data['contacts'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractItem(Map<String, dynamic> response) {
    final data = response['data'] ?? response['message'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
