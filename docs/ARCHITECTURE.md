# PlayTap — Architecture

> Principes généraux et interdiction de logique par-sport : voir
> `CLAUDE.md` section "Architecture générique". Ce document détaille
> l'organisation technique.

## Dossiers

```
/mobile        Flutter — iOS + Android
/apple-watch   SwiftUI / watchOS
/wear-os       Kotlin + Compose for Wear OS
/contracts     fixtures JSON de conformité inter-plateformes
/docs          documentation
/.claude       instructions et skills PlayTap
```

## Moteurs génériques (core)

| Moteur | Rôle | Skill |
|---|---|---|
| Score Engine | Scoring générique tous sports | `playtap-score-engine` |
| Match Engine | Périodes/clock/overtime pour les sports d'équipe (Basketball/Football/Futsal), composé avec le Score Engine — voir `docs/DATA_MODEL.md` "MatchRule" | `playtap-score-engine` |
| Shootout Engine | Tirs au but génériques (Football/Futsal), séparé du score du match | `playtap-score-engine` |
| Timer Engine | Temps fiable — monotonic/elapsed en exécution, timestamps pour la persistence | `playtap-timer-engine` |
| Interval Engine | Cycles work/rest | `playtap-interval-engine` |
| Workout Sequence Engine | Séquences d'étapes hétérogènes | `playtap-workout-engine` |
| Session Engine | Cycle de vie d'une activité (start/pause/resume/end) | — (transverse aux autres) |
| Event Engine | Event sourcing partagé par les moteurs ci-dessus | — (transverse) |
| History Engine | Lecture/agrégation de l'historique des sessions | — (transverse) |

Les moteurs "transverses" (Session, Event, History) ne sont pas des
modules séparés isolés mais des responsabilités partagées par Score/
Timer/Interval/Workout — un `ScoreEvent` et une transition d'`Interval`
utilisent le même mécanisme d'event sourcing sous-jacent.

Le Match Engine ne duplique pas la logique de clock du Timer Engine : les
deux partagent une primitive pure extraite, `ClockAccumulator`
(`mobile/lib/domain/engines/clock_engine.dart`) — running-since/
accumulated-ms, indépendante de tout event/session/sport. Le Timer Engine
l'utilise pour Stopwatch/Countdown/Lap Timer ; le Match Engine l'utilise
pour le clock de chaque période, remis à zéro à chaque `PERIOD_STARTED`.

## Où vit la logique métier

- La logique des moteurs (Score/Timer/Interval/Workout) vit **côté
  Flutter (`/mobile`)** en Dart, partagée conceptuellement — chaque
  plateforme watch réimplémente les règles nécessaires à un
  fonctionnement autonome offline (voir `playtap-watch-sync`), mais la
  définition de référence des `ScoreRule`/presets vit côté mobile.
- Watch (Apple/Wear) : UI native + exécution locale minimale nécessaire à
  l'autonomie de session (voir `playtap-watch-ux`, `playtap-watch-sync`).

## Contrats multi-plateformes (garantie d'équivalence)

Trois implémentations indépendantes (Dart, Swift, Kotlin) des mêmes
moteurs créent un risque de divergence silencieuse. `/contracts` fournit
des fixtures JSON indépendantes du langage (input events + état attendu)
que chaque plateforme doit rejouer et valider à l'identique — voir
`docs/CONFORMANCE.md` pour le format complet, le versioning, et la
procédure à suivre en cas de divergence détectée. Aucune plateforme ne
doit implémenter une règle différemment des deux autres sans faire
évoluer le contrat en premier.

## Communication phone ↔ watch

Voir `docs/WATCH_SYNC.md` et le skill `playtap-watch-sync`.

## Stockage

**Décision retenue (Phase 1A) : SQLite via Drift** pour `/mobile`.
Justification et détail : `docs/DATA_MODEL.md` et le skill
`playtap-offline-first`. Les watches utilisent un stockage natif minimal
propre à chaque plateforme (pas Drift) — voir `docs/DATA_MODEL.md`.

## Outillage de build/test

- Flutter : `flutter analyze`, `flutter test`, `dart format`.
- Apple : XcodeBuildMCP (build/test/run simulateur, puis device) — **non
  disponible sur cette machine de développement**, délibérément (Xcode
  complet non installé, seulement les Command Line Tools). Ce n'est plus
  traité comme un blocker du développement courant : c'est une contrainte
  d'environnement connue. Le build/la validation Apple se font plus tard
  dans un environnement macOS CI/build distant, disposant de Xcode — voir
  `CLAUDE.md` section "Stratégie Apple" et `apple-watch/README.md`.
- Android/Wear : Gradle (wrapper committé dans `/wear-os`).
- Tests de parcours : Mobile MCP.
- Docs à jour des libs : Context7 (voir règle dans `CLAUDE.md`) — pour les
  versions de packages Gradle/Maven, vérifier aussi directement
  `maven-metadata.xml` sur `dl.google.com`/Maven Central quand Context7 ne
  couvre pas la librairie (cas rencontré pour Wear Compose).

Checklist complète avant release : `docs/RELEASE_CHECKLIST.md` et skill
`playtap-release-gate`.
