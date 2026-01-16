import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _defaultApiBaseUrl = 'http://localhost:4000/api/v1';

  static String get apiBaseUrl {
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
