import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

final apiBaseUrlProvider = Provider<String>((ref) {
  return AppConfig.apiBaseUrl;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ref.watch(apiBaseUrlProvider));
});

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = _resolve(path);
    final response = await _client
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _decodeJson(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? 'Unexpected server response.',
        statusCode: response.statusCode,
      );
    }

    return json;
  }

  Uri _resolve(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'data': decoded};
  }

  String? _extractMessage(Map<String, dynamic> json) {
    final message = json['message'] ?? json['error'] ?? json['detail'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }
}
