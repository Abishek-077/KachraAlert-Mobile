import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class UserProfileApiService {
  UserProfileApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String accessToken,
  }) async {
    final response = await _client.postMultipart(
      ApiEndpoints.profilePhoto,
      fields: const {},
      files: [
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: filename.isNotEmpty ? filename : 'profile.jpg',
          contentType: _resolveContentType(bytes, filename),
        ),
      ],
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

  MediaType? _resolveContentType(Uint8List bytes, String filename) {
    final mimeType = lookupMimeType(filename, headerBytes: bytes);
    if (mimeType == null || mimeType.isEmpty) {
      return null;
    }
    return MediaType.parse(mimeType);
  }
}

final userProfileApiServiceProvider = Provider<UserProfileApiService>((ref) {
  return UserProfileApiService(client: ref.watch(apiClientProvider));
});
