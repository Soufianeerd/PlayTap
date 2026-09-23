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

## ScoreRule — composition de TARGET_SCORE et TEAM_SCORE

Voir `playtap-score-engine` pour le modèle conceptuel complet. Décision
architecturale (Phase Pétanque, 2026-09) : TARGET_SCORE ("premier à N
points gagne") et TEAM_SCORE ("scoring avec incréments configurables") ne
sont pas des modes mutuellement exclusifs au même niveau que FREE_SCORE —
Pétanque a besoin des deux à la fois (cible 13 + 1 à 6 points par mène).

Plutôt que d'ajouter un troisième sous-type scellé par combinaison de
modes, la logique "comment le match se termine" est factorisée dans un
objet de valeur réutilisable et composable, `ScoreTarget` (+ `ScoreWinBy`
pour la marge optionnelle) :

```jsonc
// TARGET_SCORE — toujours un ScoreTarget, incréments fixes à 1/event
{ "schemaVersion": 1, "mode": "TARGET_SCORE", "sides": ["side_a", "side_b"],
  "targetScore": 11, "automaticCompletion": true,
  "winBy": { "enabled": true, "margin": 2 } }

// TEAM_SCORE — incréments configurables, ScoreTarget optionnel et imbriqué
// sous "target" (composition : présent = Pétanque, absent = Basketball/
// Football V2, fin manuelle uniquement)
{ "schemaVersion": 1, "mode": "TEAM_SCORE", "sides": ["team_a", "team_b"],
  "allowedIncrements": [1, 2, 3, 4, 5, 6],
  "target": { "targetScore": 13, "automaticCompletion": true } }
```

`ScoreEngine` partage un seul cœur de replay (`_replayPointBased`) pour
ces deux modes — `FreeScoreRule` garde son propre chemin, inchangé, pour
zéro risque de régression. Le `ScoreState` dérivé porte aussi `rounds:
List<ScoreRound>` (une entrée par `POINT_SCORED` non-annulé) : pour
Pétanque, une **mène = un seul `POINT_SCORED`** (une seule équipe marque
par mène, voir `playtap-sports-rules`), donc son numéro est simplement la
position de l'entrée dans `rounds` — pas de nouveau type d'event
(`ROUND_COMPLETED`) ni de métadonnée de mène redondante. `FreeScoreRule`
laisse toujours `rounds` vide (aucune notion de round). L'undo reste
toujours possible, y compris pour rouvrir un match qu'une mène venait de
terminer automatiquement (voir "Undo obligatoire" dans
`playtap-score-engine`).

`ScoringSide` porte en plus un champ optionnel `players: List<String>?` —
un side de scoring peut contenir plusieurs joueurs (ex : Pétanque
doublette/triplette = 2 ou 3 joueurs dans 1 side), sans introduire de
classe `Team`/`Competitor` séparée pour ce seul besoin d'affichage.

## MatchRule — composition pour les sports à périodes/clock/overtime

Décision architecturale (Phase Sports 2, 2026-09) : Basketball, Football,
et Futsal réutilisent `TeamScoreRule` inchangé (avec `target: null` —
c'est exactement le slot documenté ci-dessus comme "Basketball/Football
V2, fin manuelle uniquement") pour le score, et ajoutent une nouvelle
configuration `MatchRule` pour tout ce que `ScoreRule` ne représente pas :
périodes, clock (running vs. stopped), prolongation, tirs au but.

`MatchRule` est **une seule classe concrète**, pas une hiérarchie scellée
comme `ScoreRule` : la machine à états (avancer dans les périodes, faire
tourner un clock, décider prolongation/tirs au but/nul) est identique pour
les trois sports — seuls les nombres/booléens diffèrent. Une hiérarchie
scellée par sport inviterait exactement le branchement `if (sport == ...)`
que l'architecture générique interdit.

```jsonc
{
  "schemaVersion": 1,
  "rulesetId": "basketball.fiba.2024",       // opaque, jamais une branche
  "scoreRule": { /* TeamScoreRule, target absent */ },
  "clock": "STOPPED_CLOCK",                   // ou "RUNNING_CLOCK"
  "periods": [ { "index": 0, "durationMs": 600000 }, /* ... */ ],
  "overtime": { "durationMs": 300000 },       // maxCount absent = illimité
  "shootout": { "kicksPerRound": 5, "suddenDeath": true }, // optionnel
  "matchEnd": { "drawAllowed": false }
}
```

**`OvertimeRule.maxCount` porte une double sémantique, purement
data-driven** (voir le commentaire complet sur `overtime_rule.dart`) :

- **absent (illimité)** : chaque prolongation est décisive seule — le
  match se termine dès qu'elle n'est plus à égalité (Basketball, FIBA
  Article 8 : jamais de match nul).
- **présent (bloc de longueur fixe)** : exactement N prolongations sont
  toujours jouées intégralement avant toute décision, quel que soit le
  score en cours de route (Football/Futsal, prolongation 2×15 ou 2×5) —
  ce n'est qu'une fois le bloc épuisé que le niveau du score est vérifié.

`rulesetId` est un identifiant opaque persisté (`basketball.fiba.2024`,
`football.ifab.2026_27`, `futsal.fifa.2025_26`) — jamais une branche dans
l'engine, seulement une donnée de traçabilité/affichage. Le `MatchRule`
**entièrement résolu** (pas seulement son id) est persisté dans
`SESSION_STARTED.payload['matchRule']` au moment de la création de la
session : une session démarrée avant un changement de règles (ex. le
basculement FIBA 2024→2026 au 2026-10-01) rejoue à l'identique pour
toujours, même après que l'app change son défaut — voir
`mobile/lib/domain/rulesets/basketball_rulesets.dart`.

**Undo inter-engines** : `ScoreEngine` et `MatchEngine` (+ `ShootoutEngine`
une fois les tirs au but commencés) rejouent chacun le même log filtré à
son propre sous-ensemble d'events. Un `UNDO` sans cible explicite serait
ambigu entre les trois — le contrôleur (jamais un engine pur) résout donc
toujours "l'event le plus récent significatif" dans le log brut
(`resolveMatchUndoTarget`) et l'annule via `targetEventId`, jamais via le
fallback implicite "dernier point" (réservé à Pétanque/Score libre, où
l'ambiguïté ne peut pas exister).

**Nouveaux `SessionEventType`** (voir `session_event.dart`) : `PERIOD_
STARTED`, `PERIOD_ENDED`, `ADDED_TIME_ANNOUNCED`, `SHOOTOUT_STARTED`,
`SHOOTOUT_ATTEMPT`, `SHOOTOUT_COMPLETED`. Réutilisés sans changement (même
sens réel) : `SESSION_STARTED`/`SESSION_COMPLETED` (début/fin de match),
`POINT_SCORED`/`UNDO`, `TIMER_STARTED`/`TIMER_PAUSED`/`TIMER_RESUMED`/
`TIMER_COMPLETED` (start/pause/resume/expiration du clock de match, toujours
en paire avec `PERIOD_STARTED`/`PERIOD_ENDED`). Aucun event nommé par
sport (jamais `BASKETBALL_POINT`/`FOOTBALL_GOAL`) ; la prolongation est
repliée dans le payload de `PERIOD_STARTED` (`kind: "OVERTIME"`) plutôt
que d'être un type d'event séparé.

**Périmètre v1 (Phase Sports 2A)** : temps morts, fautes cumulées
(Futsal), fautes d'équipe/bonus (Basketball) étaient différés — voir
"ShotClockRule/TimeoutRule/TeamFoulRule" ci-dessous pour leur ajout
(Phase Sports 2B, additif, pas de bump de `schemaVersion`).

## ShotClockRule / TimeoutRule / TeamFoulRule — Phase Sports 2B

Trois champs optionnels supplémentaires sur `MatchRule`
(`shotClockRule`/`timeoutRule`/`teamFoulRule`, tous `null` par défaut —
absent = le sport ne l'utilise pas, ex. Football n'a aucun des trois).

```jsonc
{
  // ... champs MatchRule existants ...
  "shotClockRule": { "schemaVersion": 1, "defaultDurationMs": 24000, "shortResetDurationMs": 14000 },
  "timeoutRule": {
    "schemaVersion": 1,
    "regulationGroups": [
      { "periodIndices": [0, 1], "quota": 2 },
      { "periodIndices": [2, 3], "quota": 3 }
    ],
    "quotaPerOvertimePeriod": 1,
    "lateGameSubCap": { "periodIndex": 3, "remainingMsThreshold": 120000, "maxUsableWithinWindow": 2 }
  },
  "teamFoulRule": { "schemaVersion": 1, "bonusThreshold": 5 }
}
```

**`ShotClockRule`/`ShotClockEngine`** (Basketball uniquement — pas de
concept équivalent en Football/Futsal) réutilise `ClockAccumulator`, la
même primitive que `TimerEngine`/`MatchEngine` — un `SHOT_CLOCK_RESET`
démarre une nouvelle "leg" (nouvel accumulateur, nouvelle durée cible
24000/14000ms), qui continue de tourner immédiatement si l'ancienne
tournait déjà (un reset arrive à un instant où le ballon est vivant), sans
jamais deviner la raison du reset (voir `docs/SPORT_RULES.md`). Il n'existe
pas de `SHOT_CLOCK_RESUMED` séparé : `SHOT_CLOCK_STARTED` sert à la fois de
premier départ (leg fraîche après un reset) et de reprise après une pause
— `ShotClockEngine` distingue les deux cas via l'état courant de
l'accumulateur, jamais via un type d'event différent.

**`TimeoutRule`/`TimeoutEngine`** est **une seule abstraction générique**
réutilisée par Basketball et Futsal malgré des règles superficiellement
différentes : `regulationGroups` (liste de `{periodIndices, quota}`)
exprime aussi bien le groupement par demi-terrain de Basketball (Q1-Q2
partagent un quota de 2, Q3-Q4 un quota de 3) que le groupement par
période individuelle de Futsal (chaque période son propre quota de 1) —
sans aucune branche par sport dans l'engine, uniquement des données
différentes. `lateGameSubCap` (optionnel) exprime la règle FIBA "au plus 2
des 3 temps morts de la 2e mi-temps utilisables dans les 2 dernières
minutes du Q4" comme une contrainte supplémentaire calculée depuis le
contexte du match au moment de la prise (`TimeoutRecord` capture
`periodIndex`/`isOvertimePeriod`/`overtimeCount`/
`periodRemainingMsAtTime` *au moment même* de l'event `TIMEOUT_TAKEN`,
plutôt que de rejouer `MatchState` en parallèle pour le reconstruire —
voir `playtap-score-engine` "Déterminisme").

**`TeamFoulRule`/`TeamFoulEngine`** est également **une seule abstraction
générique** couvrant le bonus Basketball (Article 41, seuil 5) et le
DFKSAF Futsal (Law 12/13, seuil 6) : seul `bonusThreshold` diffère entre
les deux rulesets. Le comportement de remise à zéro/report — remis à zéro
à chaque `PERIOD_STARTED` de type `REGULATION`, jamais remis à zéro en
entrant en prolongation (`kind: OVERTIME`) — a été vérifié officiellement
identique pour les deux sports (voir `docs/SPORT_RULES.md`), donc câblé
directement dans l'engine plutôt que configurable par ruleset ; réutilise
l'event `PERIOD_STARTED` déjà émis par `MatchEngine` plutôt que d'en
introduire un second.

**Nouveaux `SessionEventType`** : `SHOT_CLOCK_STARTED`, `SHOT_CLOCK_
PAUSED`, `SHOT_CLOCK_RESET`, `SHOT_CLOCK_COMPLETED`, `TIMEOUT_TAKEN`,
`TEAM_FOUL_ADDED`. `UNDO` est réutilisé sans changement pour les trois
(toujours avec `targetEventId` explicite, jamais le fallback implicite
"dernier point" réservé à Pétanque/Score libre) ; les trois nouveaux types
d'action rejoignent `resolveMatchUndoTarget`'s ensemble d'events
annulables au même titre qu'un point ou une fin de période.

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
| `MatchRule` | champ `schemaVersion` dans le config lui-même |
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
