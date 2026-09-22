import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/data/local/app_database.dart';
import 'package:playtap/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// See test/widget_test.dart for why these mirror `freshTestDb`/`appWithDb`
/// — duplicated here instead of shared, so this file stays a standalone,
/// easy-to-scan spec for locale behavior (docs/LOCALIZATION.md "Tests").
AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget appWithFreshDb() => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(freshTestDb())],
  child: const PlayTapApp(),
);

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

void setSystemLocales(WidgetTester tester, List<Locale> locales) {
  tester.platformDispatcher.localesTestValue = locales;
  tester.platformDispatcher.localeTestValue = locales.first;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
}

Future<void> selectLanguage(WidgetTester tester, String endonymOrAuto) async {
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();
  // The language list has 12 rows — some (e.g. the CJK entries near the
  // bottom) start outside the default test viewport's cache extent and
  // aren't mounted until scrolled into view.
  await tester.scrollUntilVisible(find.text(endonymOrAuto), 100);
  await tester.tap(find.text(endonymOrAuto));
  await tester.pumpAndSettle();
  // Not `tester.pageBack()`: it looks up the back button by its literal
  // English "Back" tooltip, which GlobalMaterialLocalizations translates
  // per locale — it would stop finding the button the moment the app
  // isn't in English. `BackButton` is a stable widget type instead.
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('A supported system locale (French) is used automatically', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('fr')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('Compter un score'), findsOneWidget);
  });

  testWidgets('An unsupported system locale falls back to English', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('xx')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('Keep score'), findsOneWidget);
  });

  testWidgets('Explicit French selection overrides an English system locale '
      'immediately, without a restart', (tester) async {
    setSystemLocales(tester, [const Locale('en')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    expect(find.text('Keep score'), findsOneWidget);

    await selectLanguage(tester, 'Français');

    expect(find.text('Compter un score'), findsOneWidget);
  });

  testWidgets('Explicit English selection overrides a French system locale', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('fr')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    expect(find.text('Compter un score'), findsOneWidget);

    await selectLanguage(tester, 'English');

    expect(find.text('Keep score'), findsOneWidget);
  });

  testWidgets('Explicit Arabic selection activates a right-to-left layout', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );

    await selectLanguage(tester, 'العربية');

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    // The category label itself switched too — not just the direction.
    expect(find.text('تسجيل النتيجة'), findsOneWidget);
  });

  testWidgets('Switching back to Automatic follows the system locale again', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('de')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await selectLanguage(tester, 'English');
    expect(find.text('Keep score'), findsOneWidget);

    await selectLanguage(tester, 'Automatic');
    expect(find.text('Punkte zählen'), findsOneWidget);
  });

  testWidgets('The language preference survives a simulated app restart', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('en')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await selectLanguage(tester, 'Français');
    expect(find.text('Compter un score'), findsOneWidget);

    // Simulate an app restart: tear the tree down and rebuild fresh. The
    // in-memory shared_preferences fake is a process-level singleton (not
    // tied to the widget tree), exactly like the real plugin persists
    // across a real relaunch — see app/locale/locale_repository.dart.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('Compter un score'), findsOneWidget);
  });

  testWidgets('Switching language never affects Score session behavior', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await selectLanguage(tester, 'Deutsch');
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.categoryScore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.startButton));
    await tester.pumpAndSettle();

    final player1 = l10n.defaultParticipantName(1);
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();

    // The score itself is always plain ASCII digits, regardless of
    // language — see docs/LOCALIZATION.md "RTL" and "chiffres".
    expect(find.text('2'), findsOneWidget);
  });

  for (final (endonym, expectedCategoryScore) in [
    ('日本語', 'スコアをつける'),
    ('한국어', '점수 기록하기'),
    ('简体中文', '记录比分'),
  ]) {
    testWidgets('Smoke test: selecting $endonym renders without error', (
      tester,
    ) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();

      await selectLanguage(tester, endonym);

      expect(tester.takeException(), null);
      expect(find.text(expectedCategoryScore), findsOneWidget);
    });
  }

  testWidgets('zh-CN system locale resolves to Simplified Chinese', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('zh', 'CN')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('记录比分'), findsOneWidget);
  });

  testWidgets('zh-TW system locale resolves to Traditional Chinese', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('zh', 'TW')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('記錄比分'), findsOneWidget);
  });

  testWidgets('zh-HK system locale also resolves to Traditional Chinese', (
    tester,
  ) async {
    setSystemLocales(tester, [const Locale('zh', 'HK')]);

    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('記錄比分'), findsOneWidget);
  });
}
