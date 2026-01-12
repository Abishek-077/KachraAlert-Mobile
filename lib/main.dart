import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/hive/hive_service.dart';
import 'core/services/storage/user_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local persistence
  final prefs = await SharedPreferences.getInstance();
  await HiveService.init();

  runApp(
    ProviderScope(
      overrides: [
        // ✅ required by UserSessionService (and any other prefs-backed services)
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KachraAlertApp(),
    ),
  );
}
