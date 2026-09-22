import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'locale/app_locale_preference.dart';
import 'providers/locale_providers.dart';
import 'router.dart';
import 'theme/theme.dart';

class PlayTapApp extends ConsumerStatefulWidget {
  const PlayTapApp({super.key});

  @override
  ConsumerState<PlayTapApp> createState() => _PlayTapAppState();
}

class _PlayTapAppState extends ConsumerState<PlayTapApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    final localePreference = ref.watch(localePreferenceProvider);

    return MaterialApp.router(
      title: 'PlayTap',
      debugShowCheckedModeBanner: false,
      theme: PlayTapTheme.light(),
      darkTheme: PlayTapTheme.dark(),
      themeMode: ThemeMode.system,
      locale: localePreference.explicitLocale,
      localeListResolutionCallback: (deviceLocales, supportedLocales) =>
          resolveSupportedLocale(deviceLocales, supportedLocales),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
