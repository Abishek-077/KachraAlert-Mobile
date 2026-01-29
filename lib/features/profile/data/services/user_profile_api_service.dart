import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class UserProfileApiService {
  UserProfileApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required String accessToken,
  }) async {
    final response = await _client.postJson(
      ApiEndpoints.profilePhoto,
      {
        'image': {
          'name': filename.isNotEmpty ? filename : 'profile.jpg',
          'mimeType': mimeType.isNotEmpty ? mimeType : 'image/jpeg',
          'dataBase64': base64Encode(bytes),
        },
      },
      accessToken: accessToken,
    );

    final data = response['data'] ?? response['user'] ?? response;
    if (data is Map<String, dynamic>) {
      final url = data['profilePhotoUrl']?.toString().trim();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    throw const ApiException('Failed to update profile photo.');
  }
}

final userProfileApiServiceProvider = Provider<UserProfileApiService>((ref) {
  return UserProfileApiService(client: ref.watch(apiClientProvider));
});
