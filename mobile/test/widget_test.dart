import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playtap/app/app.dart';

void main() {
  testWidgets('Home shows the PlayTap title and the four sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PlayTapApp()));
    await tester.pumpAndSettle();

    expect(find.text('PlayTap'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between the four tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PlayTapApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    expect(
      find.text('La bibliothèque d\'activités sera disponible ici.'),
      findsOneWidget,
    );

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

  testWidgets('Tapping a Home section navigates to the coming-soon page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PlayTapApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Score'));
    await tester.pumpAndSettle();

    expect(find.text('En cours de construction interne'), findsOneWidget);
  });
}
