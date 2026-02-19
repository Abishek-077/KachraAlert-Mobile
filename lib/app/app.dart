import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/features/admin/presentation/providers/global_listeners.dart';

import '../core/extensions/async_value_extensions.dart';
import '../core/localization/app_localizations.dart';
import '../core/motion/motion_profile.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/providers/settings_providers.dart';

class KachraAlertApp extends ConsumerWidget {
  const KachraAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(globalAdminAlertSoundListenerProvider);

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kachra Alert',
      theme: AppTheme.light(locale: locale),
      darkTheme: AppTheme.dark(locale: locale),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.maybeOf(context);
        final profile = MotionProfile.resolve(
          reduceMotionPreference: settings?.reduceMotion ?? false,
          hapticsEnabledPreference: settings?.hapticsEnabled ?? true,
          disableAnimations: mediaQuery?.disableAnimations ?? false,
        );
        final effectiveMedia = mediaQuery?.copyWith(
              disableAnimations:
                  mediaQuery.disableAnimations || profile.reduceMotion,
            ) ??
            MediaQueryData.fromView(View.of(context));

        return MotionProfileScope(
          profile: profile,
          child: MediaQuery(data: effectiveMedia, child: child),
        );
      },
      routerConfig: router,
    );
  }
}
