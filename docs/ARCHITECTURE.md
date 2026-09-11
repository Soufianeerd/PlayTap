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

Voir `docs/DATA_MODEL.md` et le skill `playtap-offline-first`.

## Outillage de build/test

- Flutter : `flutter analyze`, `flutter test`.
- Apple : XcodeBuildMCP (build/test/run simulateur, puis device).
- Android/Wear : build Gradle natif.
- Tests de parcours : Mobile MCP.
- Docs à jour des libs : Context7 (voir règle dans `CLAUDE.md`).

Checklist complète avant release : `docs/RELEASE_CHECKLIST.md` et skill
`playtap-release-gate`.
