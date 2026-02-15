import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AuthUser {
  final String userId;
  final String email;
  final String role;
  final String? profilePhotoUrl;
  final String? accessToken;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.role,
    this.profilePhotoUrl,
    this.accessToken,
  });
}

class AuthApiService {
  AuthApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<AuthUser> signup({
    required String email,
    required String password,
    required String phone,
    required String society,
    required String building,
    required String apartment,
    required bool termsAccepted,
    required String fullName,
    required String role,
    String? adminCode,
  }) async {
    final response = await _client.postJson(ApiEndpoints.signup, {
      'email': email,
      'password': password,
      'accountType': role,
      'role': role,
      'name': fullName,
      'phone': phone,
      'society': society,
      'building': building,
      'apartment': apartment,
      'terms': termsAccepted,
      if (adminCode != null && adminCode.trim().isNotEmpty) 'adminCode': adminCode.trim(),
    });

    return _parseUser(
      response,
      fallbackEmail: email,
      fallbackRole: role,
    );
  }

  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
    String? adminCode,
  }) async {
    final response = await _client.postJson(ApiEndpoints.login, {
      'email': email,
      'password': password,
      if (adminCode != null && adminCode.trim().isNotEmpty) 'adminCode': adminCode.trim(),
    });

    return _parseUser(response, fallbackEmail: email, fallbackRole: role);
  }

  AuthUser _parseUser(
    Map<String, dynamic> response, {
    required String fallbackEmail,
    required String fallbackRole,
  }) {
    final data = _extractUserPayload(response);
    final accessToken = _extractAccessToken(response);

    final userId =
        _stringValue(data['userId']) ??
        _stringValue(data['id']) ??
        _stringValue(data['_id']);

    if (userId == null || userId.isEmpty) {
      throw const ApiException('Unexpected server response.');
    }

    final email = _stringValue(data['email']) ?? fallbackEmail;
    final role =
        _stringValue(data['role']) ??
        _stringValue(data['accountType']) ??
        fallbackRole;
    final profilePhotoUrl =
        _stringValue(data['profilePhotoUrl']) ??
        _stringValue(data['profileImageUrl']);

    return AuthUser(
      userId: userId,
      email: email,
      role: role,
      profilePhotoUrl: profilePhotoUrl,
      accessToken: accessToken,
    );
  }

  Map<String, dynamic> _extractUserPayload(Map<String, dynamic> response) {
    final candidates = [
      response['data'],
      response['user'],
      response['account'],
      response['payload'],
      response,
    ];

    for (final entry in candidates) {
      if (entry is Map<String, dynamic>) {
        if (entry['user'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(entry['user'] as Map);
        }
        return entry;
      }
    }

    return response;
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  String? _extractAccessToken(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['accessToken'],
      response['access_token'],
      response['token'],
    ];

    final data = response['data'] ?? response['payload'] ?? response['user'];
    if (data is Map<String, dynamic>) {
      candidates.addAll([
        data['accessToken'],
        data['access_token'],
        data['token'],
      ]);

      final nested = data['tokens'];
      if (nested is Map<String, dynamic>) {
        candidates.addAll([
          nested['accessToken'],
          nested['access_token'],
          nested['token'],
        ]);
      }
    }

    for (final candidate in candidates) {
      final value = _stringValue(candidate);
      if (value != null) {
        return value;
      }
    }

    return null;
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(client: ref.watch(apiClientProvider));
});
