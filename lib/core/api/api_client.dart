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
  final Map<String, String> _cookies = {};

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload, {
    String? accessToken,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path);
    final response = await _client
        .post(
          uri,
          headers: _buildHeaders(
            accessToken: accessToken,
            headers: headers,
            includeJsonContentType: true,
          ),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    _storeCookies(response);

    if (response.statusCode == 204) {
      return <String, dynamic>{};
    }

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _safeDecode(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? _fallbackMessage(body),
        statusCode: response.statusCode,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? accessToken,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path);
    final response = await _client
        .get(
          uri,
          headers: _buildHeaders(accessToken: accessToken, headers: headers),
        )
        .timeout(const Duration(seconds: 20));
    _storeCookies(response);

    if (response.statusCode == 204) {
      return <String, dynamic>{};
    }

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _safeDecode(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? _fallbackMessage(body),
        statusCode: response.statusCode,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> payload, {
    String? accessToken,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path);
    final response = await _client
        .put(
          uri,
          headers: _buildHeaders(
            accessToken: accessToken,
            headers: headers,
            includeJsonContentType: true,
          ),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    _storeCookies(response);

    if (response.statusCode == 204) {
      return <String, dynamic>{};
    }

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _safeDecode(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? _fallbackMessage(body),
        statusCode: response.statusCode,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? accessToken,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path);
    final response = await _client
        .delete(
          uri,
          headers: _buildHeaders(accessToken: accessToken, headers: headers),
        )
        .timeout(const Duration(seconds: 20));
    _storeCookies(response);

    if (response.statusCode == 204) {
      return <String, dynamic>{};
    }

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _safeDecode(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? _fallbackMessage(body),
        statusCode: response.statusCode,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> payload, {
    String? accessToken,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path);
    final response = await _client
        .patch(
          uri,
          headers: _buildHeaders(
            accessToken: accessToken,
            headers: headers,
            includeJsonContentType: true,
          ),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    _storeCookies(response);

    if (response.statusCode == 204) {
      return <String, dynamic>{};
    }

    final body = response.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : _safeDecode(body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(json) ?? _fallbackMessage(body),
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

  Map<String, String> _buildHeaders({
    String? accessToken,
    Map<String, String>? headers,
    bool includeJsonContentType = false,
  }) {
    final merged = <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      ...?headers,
    };

    final token = accessToken?.trim();
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }

    if (_cookies.isNotEmpty && !merged.containsKey('Cookie')) {
      merged['Cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }

    return merged;
  }

  void _storeCookies(http.Response response) {
    final rawCookies = response.headers['set-cookie'];
    if (rawCookies == null || rawCookies.isEmpty) return;

    final cookies = rawCookies.split(RegExp(r',(?=[^;]+?=)'));
    for (final cookie in cookies) {
      final firstPair = cookie.split(';').first.trim();
      if (firstPair.isEmpty) continue;
      final separatorIndex = firstPair.indexOf('=');
      if (separatorIndex <= 0) continue;
      final name = firstPair.substring(0, separatorIndex).trim();
      final value = firstPair.substring(separatorIndex + 1).trim();
      if (name.isEmpty) continue;
      _cookies[name] = value;
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  String? _extractMessage(Map<String, dynamic> json) {
    final message = json['message'] ?? json['error'] ?? json['detail'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  String _fallbackMessage(String body) {
    if (body.isEmpty) return 'Unexpected server response.';
    return body.length > 200 ? body.substring(0, 200) : body;
  }
}
