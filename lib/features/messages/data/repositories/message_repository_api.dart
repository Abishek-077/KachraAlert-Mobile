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

  Future<List<ChatContact>> getContacts() async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      '${ApiEndpoints.messages}/contacts',
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(ChatContact.fromJson).toList();
  }

  Future<List<ChatMessage>> getConversation(String contactId) async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      '${ApiEndpoints.messages}/${Uri.encodeComponent(contactId)}',
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
