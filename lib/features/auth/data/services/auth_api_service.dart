import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AuthUser {
  final String userId;
  final String email;
  final String role;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.role,
  });
}

class AuthApiService {
  AuthApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<AuthUser> signup({
    required String email,
    required String password,

    // New preferred fields
    String? accountType,
    String? name,
    bool termsAccepted = false,

    // Existing fields
    required String phone,
    required String society,
    required String building,
    required String apartment,

    // Backward-compat (old call sites)
    @Deprecated('Use accountType instead.')
    String? role,
    @Deprecated('Use name instead.')
    String? fullName,
  }) async {
    final resolvedAccountType = (accountType ?? role)?.trim();
    final resolvedName = (name ?? fullName)?.trim();

    if (resolvedAccountType == null || resolvedAccountType.isEmpty) {
      throw const ApiException('Account type is required.');
    }
    if (resolvedName == null || resolvedName.isEmpty) {
      throw const ApiException('Name is required.');
    }

    final response = await _client.postJson(ApiEndpoints.signup, {
      'email': email,
      'password': password,
      'accountType': resolvedAccountType,
      'name': resolvedName,
      'phone': phone,
      'society': society,
      'building': building,
      'apartment': apartment,
      'terms': termsAccepted,
    });

    return _parseUser(
      response,
      fallbackEmail: email,
      fallbackRole: resolvedAccountType,
    );
  }

  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.postJson(ApiEndpoints.login, {
      'email': email,
      'password': password,
      'accountType': role,
      'role': role,
    });

    return _parseUser(
      response,
      fallbackEmail: email,
      fallbackRole: role,
    );
  }

  AuthUser _parseUser(
    Map<String, dynamic> response, {
    required String fallbackEmail,
    required String fallbackRole,
  }) {
    final data = _extractUserPayload(response);

    final userId = _stringValue(data['userId']) ??
        _stringValue(data['id']) ??
        _stringValue(data['_id']);

    if (userId == null || userId.isEmpty) {
      throw const ApiException('Unexpected server response.');
    }

    final email = _stringValue(data['email']) ?? fallbackEmail;
    final role = _stringValue(data['role']) ??
        _stringValue(data['accountType']) ??
        fallbackRole;

    return AuthUser(userId: userId, email: email, role: role);
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
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(client: ref.watch(apiClientProvider));
});
