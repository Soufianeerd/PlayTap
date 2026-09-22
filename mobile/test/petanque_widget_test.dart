// Pétanque UI flows — kept in its own file rather than appended to the
// already-large widget_test.dart (see that file's Score Libre flows for
// the mirrored pattern). Duplicates the small test harness (freshTestDb/
// appWithFreshDb/l10nOf) for the same standalone-file reason documented on
// test/app/locale_test.dart.
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

AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget appWithFreshDb() => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(freshTestDb())],
  child: const PlayTapApp(),
);

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

/// Navigates Activités -> Score -> Pétanque -> config, picks [format], fills
/// every visible team/player field with its default placeholder, and taps
/// START. Leaves the tester on the active session page.
Future<void> startPetanqueSession(
  WidgetTester tester, {
  required String format,
}) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetPetanque));
  await tester.pumpAndSettle();

  await tester.tap(find.text(format));
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.startButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'FLOW — doublette: several mènes, undo, reach 13, auto-completion, '
    'summary, history',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startPetanqueSession(tester, format: l10n.petanqueFormatDoublette);

      final teamA = l10n.petanqueDefaultTeamName(1);
      final teamB = l10n.petanqueDefaultTeamName(2);
      expect(find.text(teamA), findsWidgets);
      expect(find.text(teamB), findsWidgets);
      expect(find.text('0'), findsNWidgets(2));

      // Mène 1: team A +6.
      await tester.tap(find.text('+6').first);
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);

      // Mène 2: team B +3.
      await tester.tap(find.text('+3').last);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // Undo removes team B's whole +3 mène, not a single point.
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Mène 2 again, then push team A to 13+ (6 + 6 + 1 = 13).
      await tester.tap(find.text('+6').first);
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('+1').first);
      await tester.pumpAndSettle();

      // Auto-completion navigates straight to the summary page.
      await tester.pumpAndSettle();
      expect(find.text(l10n.summaryTitle), findsOneWidget);
      expect(find.text(l10n.winnerAnnouncement(teamA)), findsOneWidget);
      expect(find.text('13'), findsOneWidget);

      await tester.tap(find.text(l10n.viewHistoryButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.presetPetanque), findsOneWidget);
      expect(find.textContaining('$teamA 13'), findsOneWidget);
    },
  );

  testWidgets(
    'FLOW — tête-à-tête config shows exactly 1 player field per team',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.categoryScore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.presetPetanque));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.petanqueFormatHeadToHead));
      await tester.pumpAndSettle();

      // 2 team-name fields + 2 single-player fields ("Participant 1 name").
      expect(find.text(l10n.participantNameLabel(1)), findsNWidgets(2));
      expect(find.text(l10n.participantNameLabel(2)), findsNothing);
    },
  );

  testWidgets(
    'FLOW — triplette config shows exactly 3 player fields per team',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.categoryScore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.presetPetanque));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.petanqueFormatTriplette));
      await tester.pumpAndSettle();

      expect(find.text(l10n.participantNameLabel(1)), findsNWidgets(2));
      expect(find.text(l10n.participantNameLabel(2)), findsNWidgets(2));
      expect(find.text(l10n.participantNameLabel(3)), findsNWidgets(2));
    },
  );

  testWidgets('FLOW — manual abandon before 13 lands back on History', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await startPetanqueSession(tester, format: l10n.petanqueFormatDoublette);

    await tester.tap(find.text('+2').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.abandonGameButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.navHistory), findsWidgets);
    // Abandoned sessions never appear in History (distinct from COMPLETED).
    expect(find.text(l10n.presetPetanque), findsNothing);
  });
}
