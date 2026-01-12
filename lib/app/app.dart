import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/features/admin/presentation/providers/global_listeners.dart';

import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../features/settings/presentation/providers/settings_providers.dart';

class KachraAlertApp extends ConsumerWidget {
  const KachraAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ✅ Start global sound listener for admin alerts
    ref.watch(globalAdminAlertSoundListenerProvider);

    // ✅ themeModeProvider returns ThemeMode
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kachra Alert',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
