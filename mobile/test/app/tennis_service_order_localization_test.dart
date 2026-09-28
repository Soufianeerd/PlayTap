// Guards against the exact regression fixed in a1ac0d8's follow-up: new
// Tennis strings added to app_en.arb (and only app_en.arb/app_fr.arb) while
// the other 10 supported locales silently kept falling back to English —
// `flutter gen-l10n` never errors on that, it just doesn't override the
// getter (see docs/LOCALIZATION.md, "toute clé absente ... retombe sur
// l'anglais"), so nothing short of an explicit test catches it.
//
// Deliberately not a literal-translation test (fragile, and not what this
// guards against): for every non-English supported locale, each new key's
// resolved string just has to differ from the English one — proof a real
// translation exists rather than a silent fallback. `AppLocalizations` is
// looked up directly via `lookupAppLocalizations`, no widget pump needed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  final nonEnglishLocales = AppLocalizations.supportedLocales.where(
    (l) => l.languageCode != 'en',
  );

  group('Doubles service-order sheet strings are translated in every '
      'supported locale (not silently falling back to English)', () {
    for (final locale in nonEnglishLocales) {
      final l10n = lookupAppLocalizations(locale);

      test('$locale', () {
        expect(
          l10n.tennisFirstServingSideLabel,
          isNot(en.tennisFirstServingSideLabel),
          reason: '$locale: tennisFirstServingSideLabel falls back to English',
        );
        expect(
          l10n.tennisServiceOrderSheetTitle(2),
          isNot(en.tennisServiceOrderSheetTitle(2)),
          reason: '$locale: tennisServiceOrderSheetTitle falls back to English',
        );
        expect(
          l10n.tennisServiceOrderMatchTieBreakTitle,
          isNot(en.tennisServiceOrderMatchTieBreakTitle),
          reason:
              '$locale: tennisServiceOrderMatchTieBreakTitle falls back to '
              'English',
        );
        expect(
          l10n.tennisServiceOrderServingFirstLabel,
          isNot(en.tennisServiceOrderServingFirstLabel),
          reason:
              '$locale: tennisServiceOrderServingFirstLabel falls back to '
              'English',
        );
        expect(
          l10n.tennisContinueButton,
          isNot(en.tennisContinueButton),
          reason: '$locale: tennisContinueButton falls back to English',
        );
      });
    }
  });

  test('every tennis* ARB key present in the English template is also present '
      '(the getter is overridden, not silently inherited from the English '
      'base class) in every other supported locale', () {
    // Structural check, not a translation-quality one (avoids the
    // fragile trap of comparing resolved strings — tennis vocabulary
    // legitimately borrows English/international terms in several
    // languages, e.g. "No-Ad", "Sets", "Best of 3" in German/French/
    // Spanish/Portuguese, so an exact-string-match probe would flag
    // correct translations as false positives). What actually catches
    // "added to app_en.arb only" is *parsing the ARB source itself* —
    // exactly the bug class this test guards against.
    final enArb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final tennisKeys = enArb.keys.where((k) => k.startsWith('tennis'));

    final arbFileForLocale = {
      for (final locale in nonEnglishLocales)
        locale:
            'lib/l10n/app_'
            '${locale.scriptCode != null ? '${locale.languageCode}_${locale.scriptCode}' : locale.languageCode}'
            '.arb',
    };

    final missing = <String>[];
    arbFileForLocale.forEach((locale, path) {
      final arb =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final key in tennisKeys) {
        if (!arb.containsKey(key)) missing.add('$locale ($path): $key');
      }
    });

    expect(
      missing,
      isEmpty,
      reason:
          'These Tennis keys exist in app_en.arb but not in the listed '
          "locale's own ARB — gen-l10n silently falls back to English "
          'for them instead of erroring: $missing',
    );
  });
}
