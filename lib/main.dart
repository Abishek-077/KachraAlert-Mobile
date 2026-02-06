import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/services/hive/hive_service.dart';
import 'core/services/storage/user_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env values (API_BASE_URL, etc.)
  await dotenv.load(fileName: '.env');

  // Ensure intl date symbols are available for device locale (e.g. 'ne').
  await initializeDateFormatting();

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
