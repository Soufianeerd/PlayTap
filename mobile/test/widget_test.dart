import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/data/local/app_database.dart';

/// A fresh in-memory database per test (see the Phase 1B.1 brief, section
/// 27 — no data persists between tests). `closeStreamsSynchronously` avoids
/// a documented drift/flutter_test interaction: without it, closing a
/// watched query schedules a zero-duration Timer that can outlive the
/// widget tree and trip flutter_test's "pending timer" check.
AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget appWithDb(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const PlayTapApp(),
  );
}

Widget appWithFreshDb() => appWithDb(freshTestDb());

Future<void> startFreeScoreSession(
  WidgetTester tester, {
  required int participantCount,
}) async {
  await tester.tap(find.text('Score'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Score libre'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('$participantCount'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('COMMENCER'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home shows the PlayTap title and the four sections', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('PlayTap'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between the four tabs', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    expect(find.text('Score'), findsWidgets);

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune session enregistrée.'), findsOneWidget);

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucun réglage disponible pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping Timer navigates to the coming-soon page', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();

    expect(find.text('En cours de construction interne'), findsOneWidget);
  });

  testWidgets('FLOW 1 — 2 participants: score, undo, complete, history', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 2);

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Undo removes the last scoring action (Joueur 2's point).
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('TERMINER LA PARTIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER'));
    await tester.pumpAndSettle();

    // Summary screen.
    expect(find.text('Score libre'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('TERMINER'));
    await tester.pumpAndSettle();

    // Landed on History with the completed session.
    expect(find.textContaining('Joueur 1 2'), findsOneWidget);
  });

  testWidgets('FLOW 2 — 3 participants can all be scored', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 3);

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('Joueur 3'), findsOneWidget);

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 3'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget); // Joueur 1
    expect(find.text('0'), findsOneWidget); // Joueur 2
    expect(find.text('2'), findsOneWidget); // Joueur 3
  });

  testWidgets(
    'FLOW 3 — 4 participants render as a 2x2 grid and can be scored',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();

      await startFreeScoreSession(tester, participantCount: 4);

      for (var i = 1; i <= 4; i++) {
        expect(find.text('Joueur $i'), findsOneWidget);
      }

      await tester.tap(find.text('Joueur 4'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
    },
  );

  testWidgets('FLOW 4 — an active session resumes with its exact score', (
    tester,
  ) async {
    final db = freshTestDb();

    await tester.pumpWidget(appWithDb(db));
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();

    // Simulate an app restart: tear the whole tree down first (otherwise
    // Flutter just updates the existing PlayTapApp element in place and its
    // router keeps whatever route it was on) so PlayTapApp's State — and
    // the router it creates in initState — are genuinely recreated, over
    // the SAME underlying database.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(appWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text('REPRENDRE LA PARTIE'), findsOneWidget);

    await tester.tap(find.text('REPRENDRE LA PARTIE'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // Joueur 1, recovered exactly
    expect(find.text('1'), findsOneWidget); // Joueur 2, recovered exactly

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });
}
