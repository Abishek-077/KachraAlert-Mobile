import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/admin_user_model.dart';

class AdminUserRepositoryApi {
  AdminUserRepositoryApi({
    required ApiClient client,
    required this.accessToken,
  }) : _client = client;

  final ApiClient _client;
  final String? accessToken;

  Future<List<AdminUser>> getAll() async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      ApiEndpoints.adminUsers,
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(AdminUser.fromJson).toList();
  }

  Future<AdminUser> createUser({
    required String accountType,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String society,
    required String building,
    required String apartment,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = _requireAccessToken();
    final fields = <String, String>{
      'accountType': accountType,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'society': society,
      'building': building,
      'apartment': apartment,
    };

    final files = _buildImageFiles(imageBytes, imageName);
    final response = await _client.postMultipart(
      ApiEndpoints.adminUsers,
      fields: fields,
      files: files,
      accessToken: token,
    );
    return AdminUser.fromJson(_extractItem(response));
  }

  Future<AdminUser> updateUser({
    required String id,
    required String accountType,
    required String name,
    required String email,
    required String phone,
    String? password,
    required String society,
    required String building,
    required String apartment,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = _requireAccessToken();
    final fields = <String, String>{
      'accountType': accountType,
      'name': name,
      'email': email,
      'phone': phone,
      'society': society,
      'building': building,
      'apartment': apartment,
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
    };

    final files = _buildImageFiles(imageBytes, imageName);
    final response = await _client.putMultipart(
      '${ApiEndpoints.adminUsers}/$id',
      fields: fields,
      files: files,
      accessToken: token,
    );
    return AdminUser.fromJson(_extractItem(response));
  }

  Future<AdminUser> updateStatus({
    required String id,
    bool? isBanned,
    double? lateFeePercent,
  }) async {
    final token = _requireAccessToken();
    final payload = <String, dynamic>{};
    if (isBanned != null) payload['isBanned'] = isBanned;
    if (lateFeePercent != null) payload['lateFeePercent'] = lateFeePercent;
    if (payload.isEmpty) {
      throw const ApiException('No status updates provided.');
    }

    final response = await _client.patchJson(
      '${ApiEndpoints.adminUsers}/$id/status',
      payload,
      accessToken: token,
    );
    return AdminUser.fromJson(_extractItem(response));
  }

  Future<void> deleteUser(String id) async {
    final token = _requireAccessToken();
    await _client.deleteJson(
      '${ApiEndpoints.adminUsers}/$id',
      accessToken: token,
    );
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to manage users.');
    }
    return token;
  }

  List<http.MultipartFile>? _buildImageFiles(
    Uint8List? imageBytes,
    String? imageName,
  ) {
    if (imageBytes == null) return null;
    return [
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName?.trim().isNotEmpty == true
            ? imageName!.trim()
            : 'profile.jpg',
      ),
    ];
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['users'] ?? response['items'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['users'] ?? data['items'];
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
    final data = response['data'] ?? response['user'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
