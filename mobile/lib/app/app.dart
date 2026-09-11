import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/theme.dart';

class PlayTapApp extends StatefulWidget {
  const PlayTapApp({super.key});

  @override
  State<PlayTapApp> createState() => _PlayTapAppState();
}

class _PlayTapAppState extends State<PlayTapApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PlayTap',
      debugShowCheckedModeBanner: false,
      theme: PlayTapTheme.light(),
      darkTheme: PlayTapTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
