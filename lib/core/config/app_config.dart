import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _defaultApiBaseUrl = 'http://localhost:4000/api/v1';

  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }

    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return _defaultApiBaseUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/v1';
    }

    return _defaultApiBaseUrl;
  }
}
