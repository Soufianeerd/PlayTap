# PlayTap — Localization

> Fondation d'internationalisation ajoutée à la release 1.0.0 sans casser
> l'existant. Ce document explique comment le système de langue fonctionne
> et comment ajouter une langue.

## Architecture

PlayTap utilise la solution Flutter officielle : `flutter_localizations` +
`intl` + `gen-l10n`, pilotée par `mobile/l10n.yaml`. Aucun système de
traduction maison.

```
mobile/lib/l10n/
  app_en.arb        # template — source de vérité, toute nouvelle clé y
                     # est ajoutée en premier
  app_fr.arb
  app_es.arb
  app_de.arb
  app_it.arb
  app_pt.arb
  app_ar.arb
  app_ja.arb
  app_ko.arb
  app_zh.arb         # fallback générique requis par gen-l10n quand des
                     # variantes de script existent (contenu = zh_Hans,
                     # jamais sélectionnable directement — voir "Chinois")
  app_zh_Hans.arb    # chinois simplifié
  app_zh_Hant.arb    # chinois traditionnel
```

`flutter gen-l10n` (déclenché automatiquement par `flutter pub get` /
`flutter run` grâce à `generate: true` dans `pubspec.yaml`, ou à la main)
génère `AppLocalizations` dans le même dossier. Ce sont des fichiers
générés : ne jamais les éditer à la main.

## Langues supportées

Anglais, Français, Español, Deutsch, Italiano, Português, العربية, 日本語,
한국어, 简体中文, 繁體中文.

**English est le fallback universel.** Toute clé absente d'une traduction
retombe sur l'anglais (comportement natif de `gen-l10n`), et toute langue
système non supportée retombe sur l'anglais (voir "Résolution de la
langue").

## Résolution de la langue

Logique dans `mobile/lib/app/locale/app_locale_preference.dart` et
branchée dans `mobile/lib/app/app.dart` (`MaterialApp.router.locale` +
`localeListResolutionCallback`).

- Préférence `système` (défaut) : la langue de l'app suit la langue du
  téléphone si elle est supportée, sinon retombe sur l'anglais.
- Préférence explicite (`en`, `fr`, …) : force cette langue quel que soit
  le téléphone.
- Le choix est persisté localement via `shared_preferences`
  (`SharedPreferencesAsync`, l'API actuelle recommandée — voir
  `LocaleRepository`). Ce n'est **pas** une table Drift : c'est une
  préférence d'app (UI), pas une donnée de session sportive, donc elle ne
  fait pas partie du modèle défini dans `DATA_MODEL.md`.
- Le changement est immédiat (`Riverpod` `NotifierProvider` observé par
  `PlayTapApp`, pas de redémarrage nécessaire).

Écran : `mobile/lib/features/settings/language_settings_page.dart`,
accessible depuis un bouton discret (icône langue) sur Home.

## Chinois : Hans vs Hant

PlayTap ne propose que deux choix chinois explicites : **简体中文**
(Simplifié) et **繁體中文** (Traditionnel) — jamais un « chinois »
générique, ambigu entre script simplifié et traditionnel.

Règle de résolution automatique (langue système) :

- un `scriptCode` explicite du téléphone (`Hans`/`Hant`) est utilisé
  directement ;
- sinon, code pays : `CN` / `SG` → Simplifié ; `TW` / `HK` / `MO` →
  Traditionnel ;
- un `zh` totalement nu (ni script ni pays reconnu) retombe sur Simplifié
  (le plus répandu des deux).

`app_zh.arb` existe uniquement parce que `gen-l10n` exige un fichier de
base sans script/pays dès que des variantes scriptées du même langage
existent — voir la doc Flutter sur `Locale.fromSubtags`. Son contenu est
une copie du Simplifié ; il n'est **jamais** proposé comme choix dans
l'écran Langue et n'est **jamais** renvoyé par la résolution automatique
(qui choisit toujours explicitement Hans ou Hant).

## Ajouter une nouvelle langue

1. Copier `lib/l10n/app_en.arb` vers `app_<code>.arb` et traduire chaque
   valeur (garder les clés, les placeholders `{xxx}` et la syntaxe ICU
   plural intacts). Mettre à jour `"@@locale"`.
2. Traductions naturelles et courtes — jamais mot-à-mot. Le nom de la
   marque (**PlayTap**) ne se traduit jamais.
3. Ajouter la valeur correspondante dans l'enum
   `AppLocalePreference` (`app/locale/app_locale_preference.dart`),
   son `explicitLocale`, et — si la langue a un script non-latin —
   l'endonyme dans `_languageEndonyms`
   (`features/settings/language_settings_page.dart`).
4. Si la langue a plusieurs scripts/pays significativement différents
   (comme le chinois), voir "Chinois" ci-dessus comme modèle.
5. `flutter gen-l10n`, puis `flutter analyze` et `flutter test`.

## Règles de clés

- Une clé = un rôle UI précis, jamais un mot brut réutilisé par
  coïncidence entre deux écrans différents (même si la traduction
  anglaise se ressemble aujourd'hui — deux écrans peuvent diverger plus
  tard).
- Les clés qui apparaissent réellement à plusieurs endroits identiques
  (ex. `finishButton`, `cancelButton`, `resumeActivity`) sont
  volontairement partagées.
- Jamais de concaténation manuelle de mots pour former une phrase
  (`'$count ' + 'lap' + s`) — utiliser un message ICU `plural` dans l'ARB.
- Jamais une valeur de langue qui entre dans le moteur métier
  (Score/Timer/Interval/Workout Engine) : les enums, event types,
  `presetRef`, routes go_router, clés de base de données restent
  toujours en anglais technique, non traduits, indépendants de la
  langue affichée.

## Pluriels

`gen-l10n` génère une méthode par clé `plural` de l'ARB (catégories ICU
CLDR : `zero`/`one`/`two`/`few`/`many`/`other` selon ce que la langue
utilise réellement — l'arabe utilise les six, le français/anglais
`one`/`other`, le japonais/coréen/chinois seulement `other`). Toujours
passer par ce mécanisme pour un nombre visible à l'utilisateur (tours,
minutes, participants...), jamais par une concaténation manuelle.

## RTL (arabe)

- `MaterialApp` calcule automatiquement la direction du texte et des
  layouts (`Directionality`) à partir de la locale active, dès lors que
  `GlobalMaterialLocalizations`/`GlobalWidgetsLocalizations`/
  `GlobalCupertinoLocalizations` sont dans `localizationsDelegates` (déjà
  le cas). Aucune valeur RTL codée en dur nulle part.
- Les icônes directionnelles standard de Material (`Icons.chevron_right`
  par exemple) embarquent déjà `IconData.matchTextDirection: true` et se
  reflètent seules — pas de traitement spécial nécessaire pour elles.
- Les chiffres de score/timer (`_ScoreTile`, l'affichage du chrono) sont
  de l'interpolation `'$score'`/formatage manuel en ASCII pur : ils
  **restent toujours des chiffres occidentaux lisibles**, quelle que soit
  la langue — jamais remplacés par des chiffres arabes-indiens, même en
  arabe. Ne changez pas ces affichages pour passer par `NumberFormat`.
- Le format de date de l'historique (`_relativeDay` dans
  `history_page.dart`) utilise, lui, `intl.DateFormat` localisé — c'est
  un texte secondaire, pas un affichage de score/chrono, donc le format
  (et les chiffres) suivent la locale normalement.
- Testé automatiquement dans `test/app/locale_test.dart` (`Directionality`
  bascule bien en `TextDirection.rtl`, le contenu affiché change aussi).

## Sport Packs futurs

**Aucun futur Sport Pack ne doit contenir directement du texte
utilisateur dans son moteur ou sa config.** Il doit référencer des
localization keys, jamais une chaîne en dur dans une langue donnée.

Exemple attendu :

```
sportKey: basketball
nameKey: sportBasketball

drillKey: basketball_shooting_10
titleKey: drillBasketballShooting10
```

`nameKey`/`titleKey` sont résolues via `AppLocalizations` au moment de
l'affichage — jamais stockées traduites.

## Cue Engine futur

Le Cue Engine (signaux audio/voix pendant l'effort, prévu dans une
release ultérieure) aura sa propre localisation indépendante de l'UI
textuelle : les cues vocaux (ex. "3, 2, 1, go") ne partagent pas
nécessairement le même pipeline ARB que le texte à l'écran (contraintes
de synthèse vocale différentes par langue). Décision à prendre au moment
de l'implémentation, pas anticipée ici.

## Commerce Engine futur

Un pays n'est pas une langue : la disponibilité d'un moyen de paiement,
d'un abonnement ou d'une offre régionale (Commerce Engine futur) doit se
décider sur un signal de pays/région distinct de la préférence de langue
définie ici. Ne jamais dériver un pays depuis `AppLocalePreference`.

## Tests

Voir `mobile/test/app/locale_test.dart` et
`mobile/test/widget_test.dart`.

Les tests de comportement métier (`widget_test.dart`) n'assertent
**jamais** sur du texte français ou anglais codé en dur : ils lisent
`AppLocalizations.of(context)` sur l'arbre pompé et comparent contre ça,
donc ils restent valides quelle que soit la langue résolue par
l'environnement de test.
