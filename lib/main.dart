import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/hive/hive_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init(); // important
  runApp(const ProviderScope(child: KachraAlertApp()));
}
