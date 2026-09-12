# PlayTap — Data Model

> Règles de persistance et offline-first : voir skill
> `playtap-offline-first`. Ce document détaille les entités de données.

## Entités principales

```
Session
  schemaVersion: Int              // format du "sync payload" de la session
  id: UUID
  ownerDevice: PHONE | WATCH_APPLE | WATCH_WEAROS
  category: SCORE | TIMER | TRAINING | CUSTOM
  presetRef: String              // référence au preset utilisé (sport,
                                  // programme d'intervalles, workout...)
  startedAt: Timestamp
  endedAt: Timestamp?
  status: ACTIVE | PAUSED | COMPLETED | ABANDONED

Event (event sourcing — voir playtap-score-engine, playtap-interval-engine,
       playtap-workout-engine)
  id: UUID
  sessionId: UUID
  type: String                   // ex: POINT_SCORED, UNDO, PHASE_STARTED,
                                  // STEP_COMPLETED, SESSION_PAUSED...
  payload: Map                   // données spécifiques au type d'event
  timestamp: Timestamp            // horloge murale, informatif — jamais
                                   // seul juge de l'ordre entre appareils
  originDevice: PHONE | WATCH_APPLE | WATCH_WEAROS
  originSequence: Int             // compteur local incrémenté par
                                   // l'appareil émetteur pour chaque event
                                   // qu'il produit dans la session — voir
                                   // "Event ordering" dans WATCH_SYNC.md

Preset
  schemaVersion: Int              // format de Preset.config
  id: String
  category: SCORE | TIMER | TRAINING | CUSTOM
  name: String
  config: Map                    // ScoreRule / TimerSpec / IntervalProgram
                                  // / WorkoutSequence selon la catégorie
                                  // (chacun porte aussi son propre
                                  // schemaVersion, voir plus bas)
  isFavorite: Bool
  isBuiltIn: Bool                // preset fourni par PlayTap vs créé par
                                  // l'utilisateur

HistoryEntry (vue dérivée, pas une table séparée à maintenir manuellement)
  session: Session
  finalState: Map                 // MatchState / TimerState final, dérivé
                                   // par replay des Events, pas stocké
                                   // indépendamment comme source de vérité
```

## Principes

- `Event` est la source de vérité pour tout état de session. `Session`
  garde les métadonnées de cycle de vie ; l'état détaillé (score, temps,
  phase) est toujours dérivé par replay des `Event` associés — jamais
  stocké en double sans lien vers les events qui l'ont produit.
- `Preset.config` est une structure typée par catégorie ; voir
  `playtap-score-engine` (ScoreRule), `playtap-timer-engine` (TimerSpec),
  `playtap-interval-engine` (IntervalProgram), `playtap-workout-engine`
  (WorkoutSequence) pour le détail de chaque forme.
- Tout Event est horodaté et attribué à un `originDevice`, nécessaire pour
  la réconciliation décrite dans `playtap-watch-sync`. Son ordre logique
  entre appareils est déterminé par `originSequence` (et non par
  `timestamp` seul, les horloges pouvant diverger) — voir la section
  "Event ordering" de `docs/WATCH_SYNC.md`.

## schemaVersion — versioning des formats importants

Chaque format qui peut évoluer indépendamment porte son propre
`schemaVersion` (entier, commence à 1) :

| Type | Où |
|---|---|
| `Preset.config` (conteneur) | champ `schemaVersion` sur `Preset` |
| `ScoreRule` | champ `schemaVersion` dans le config lui-même |
| `TimerSpec` | champ `schemaVersion` dans le config lui-même |
| `IntervalProgram` | champ `schemaVersion` dans le config lui-même |
| `WorkoutSequence` | champ `schemaVersion` dans le config lui-même |
| Session sync payload (ce qui est échangé phone ↔ watch) | champ `schemaVersion` sur `Session` |

Règle simple : un changement rétrocompatible (ajout d'un champ optionnel)
ne nécessite pas d'incrémenter `schemaVersion`. Un changement qui casserait
une lecture par une version antérieure (renommage, changement de
sémantique, suppression) nécessite d'incrémenter `schemaVersion` et de
prévoir une migration (voir `playtap-offline-first`). Ne pas sur-designer
ce mécanisme — un entier suffit, pas de semver complexe.

## Modèle temporel : monotonic en exécution, timestamps pour la persistence

Deux besoins distincts, deux sources de temps distinctes (détail complet :
skill `playtap-timer-engine`) :

- **Pendant l'exécution locale d'un timer actif**, calculer `elapsed`/
  `remaining` à partir d'une horloge **monotonic/elapsed** adaptée à la
  plateforme (ex : `Duration` monotonic Dart, `ProcessInfo.systemUptime`/
  `DispatchTime` côté Swift, `SystemClock.elapsedRealtime()` côté Kotlin/
  Android) — jamais l'horloge murale du système, qui peut sauter (fuseau
  horaire, changement d'heure, correction NTP, l'utilisateur qui modifie
  l'heure manuellement) et casserait un timer en cours sans qu'aucun
  event réseau ne soit impliqué.
- **Pour la persistence et le recovery** (app fermée, process tué, montre
  endormie puis réveillée), on ne peut pas persister une horloge
  monotonic (elle est remise à zéro au reboot) : on conserve donc les
  `Timestamp` muraux nécessaires (`startedAt`, bornes de
  `pausedIntervals`) pour reconstruire l'état après relance — voir
  `playtap-offline-first` ("Crash recovery").

Dans tous les cas : **jamais de timer basé sur un simple `remaining--`
décrémenté à chaque tick.** L'état est toujours recalculé, jamais
accumulé.

## Stockage local (mobile) — décision définitive : SQLite via Drift

**Retenu pour le MVP : Drift (SQLite) côté Flutter.** Pas de backend.

Justification :
- offline-first : SQLite est un fichier local, aucune dépendance réseau ;
- `Session`/`Event`/`Preset` sont des données structurées et relationnelles
  (voir modèle ci-dessus) — un vrai schéma relationnel avec requêtes
  typées convient mieux qu'un simple stockage clé-valeur ;
- migrations de schéma versionnées de première classe (nécessaire pour
  `schemaVersion`, voir `playtap-offline-first`) ;
- requêtes d'historique (tri, filtres, agrégations) faciles à exprimer et
  testables sans mock ;
- Dart pur, aucun plugin natif requis pour l'essentiel (`drift`/
  `path_provider`).

Tables réelles (Phase 1B.1) : `sessions`, `events`, `presets` — schéma
exact dans `mobile/lib/data/local/tables.dart`.

### Résolution `drift_dev` (Phase 1B.1)

Le blocage documenté en Phase 1A est résolu par une **combinaison de
versions figée**, sans mutation globale (`flutter upgrade` non utilisé) :

```
drift: 2.31.0
drift_dev: 2.31.0        (dev)
build_runner: 2.15.1     (dev)
analyzer: 8.4.1          (dev, épinglage explicite)
```

Analyse (voir `mobile/pubspec.yaml` pour le détail commenté) : `riverpod`
dépend réellement (pas en dev) de `test ^1.0.0` ; `flutter_test` du SDK
fige `test_api` à une version qui résout `test` à `1.26.3`, lequel plafonne
`analyzer` à `<9.0.0`. Or `analyzer >=10.0.2` exige `meta ^1.18.0`,
indisponible avec le SDK Flutter installé (`meta` figé à `1.17.0`).
`drift_dev 2.31.0` est la dernière version dont le plancher `analyzer`
(`>=8.1.0`) tient sous ce plafond — mais elle plafonne en retour `drift`/
`sqlite3` à la ligne pré-auto-bundling (`drift <2.32`, `sqlite3 <3.0`).
Conséquence : `sqlite3_flutter_libs` (version `0.5.42`, pas la `0.6.0+eol`)
redevient nécessaire, et `drift_flutter` (qui force `sqlite3 ^3.0.0`) ne
peut plus être utilisé — la connexion native est donc ouverte à la main
(`data/local/connection.dart`, `NativeDatabase.createInBackground` +
`path_provider`), l'autre méthode de premier niveau documentée par Drift,
pas une solution de contournement.

`dart run build_runner build` génère réellement `app_database.g.dart`
avec cette combinaison — vérifié, pas supposé.

## Stockage local (watch)

Stockage natif minimal permettant l'autonomie complète d'une session
(voir `playtap-watch-sync` — "Fonctionnement montre 100% offline") :
au moins la session active courante et ses events non synchronisés, avec
transfert vers le phone dès reconnexion. **Ne pas imposer Drift aux
watches** — chaque plateforme choisit son propre stockage natif ; le
choix précis se fera pendant la phase watch (voir `docs/ROADMAP.md`).
