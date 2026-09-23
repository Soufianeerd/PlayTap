---
name: playtap-sports-rules
description: Presets sportifs V1 de PlayTap (Tennis, Padel, Tennis de table, Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score libre) exprimés comme configurations du Score Engine ou du Racket Engine (sports de raquette). Utiliser lors de l'ajout ou la modification d'un sport.
---

# PlayTap — Sports Rules (presets V1)

Chaque sport ci-dessous est un preset de `ScoreRule` **ou** du Racket
Engine (`RacketMatchRule` — Tennis/Padel/Tennis de table/Badminton, voir
`playtap-score-engine` et `docs/DATA_MODEL.md`) — jamais une
implémentation séparée par sport.

## Règle absolue : joueurs ≠ sides de scoring

Ne jamais mélanger le **nombre de `Competitor`** (joueurs physiques) et le
**nombre de `Team`** (entités qui marquent des points). Exemple canonique :

> **Padel à 4 joueurs = 2 équipes de score.**

Chaque sport ci-dessous précise explicitement les deux.

## Presets V1

### Tennis — **IMPLEMENTED** (Racket Core Phase 1)
- Joueurs : 2 (simple) ou 4 (double) → Teams de scoring : toujours 2
- Scoring : moteur dédié **Racket Engine** (`RacketMatchRule`), pas un mode
  `ScoreRule` — point → jeu (0/15/30/40, deuce/avantage ou No-Ad) → set
  (6 jeux, tie-break à 6-6 ou set à l'avantage) → match (Best of 3 en V1,
  Best of 5 supporté par l'architecture). Voir `playtap-score-engine` (le
  pourquoi de ce moteur séparé) et `docs/DATA_MODEL.md`/`docs/SPORT_RULES.md`
  pour le détail complet et la source ITF.

### Padel — NOT IMPLEMENTED
- Joueurs : 4 (toujours double) → Teams de scoring : 2 (2 joueurs/team)
- Scoring : même famille que Tennis (Racket Engine), avec une règle
  golden point configurable (pas de deuce) — s'ajouterait comme une
  valeur `AdvantageMode` supplémentaire, sans réécrire le moteur (revue de
  compatibilité faite, voir `docs/DATA_MODEL.md`). Non implémenté dans
  cette phase.

### Tennis de table
- Joueurs : 2 (simple) ou 4 (double) → Teams de scoring : 2
- Scoring : `TARGET_SCORE` (11) + `WIN_BY` (2) + `SETS` + `BEST_OF`
  (généralement 5 ou 7)

### Badminton
- Joueurs : 2 (simple) ou 4 (double) → Teams de scoring : 2
- Scoring : `TARGET_SCORE` (21) + `WIN_BY` (2, plafonné à 30) + `SETS`
  (best of 3)

### Pétanque
- Joueurs : 1 à 3 par équipe (tête-à-tête, doublette, triplette) → Teams
  de scoring : 2, quel que soit le nombre de joueurs par équipe
- Scoring : `TARGET_SCORE` (13) + `TEAM_SCORE` (incrément variable par mène,
  1 à 6 points), pas de sets

### Basketball
- Joueurs : 5 par équipe sur le terrain (configurable, non bloquant côté
  scoring) → Teams de scoring : 2
- Scoring : `TEAM_SCORE` avec incréments {1, 2, 3}, pas de sets. Quarts-temps
  optionnels (traités comme un simple découpage d'affichage, pas comme des
  `SetState` à la Tennis)

### Football / Futsal
- Joueurs : 11 (foot) ou 5 (futsal), configurable, non bloquant côté
  scoring → Teams de scoring : 2
- Scoring : `TEAM_SCORE` avec incrément fixe {1}, pas de sets

### Volleyball
- Joueurs : 6 par équipe (configurable) → Teams de scoring : 2
- Scoring : `TARGET_SCORE` (25, 15 pour le set décisif) + `WIN_BY` (2) +
  `SETS` + `BEST_OF` (3 ou 5)

### Score libre
- Joueurs : 1 à N, configurable librement par l'utilisateur → Teams de
  scoring : 1 à N (l'utilisateur définit le nombre de sides)
- Scoring : `FREE_SCORE`, incrément configurable, pas de fin automatique
  (l'utilisateur termine manuellement)

## Points d'extension identifiés (à traiter au moment de l'implémentation de chaque sport)

Tennis est **implémenté** (Racket Core Phase 1, voir ci-dessus) — sa
nuance tie-break/deuce/No-Ad est résolue par le Racket Engine dédié
(`RacketMatchRule`), pas par une extension de `ScoreRule` : c'est
précisément pourquoi ce nouveau moteur a été introduit plutôt que de
forcer un mode `ScoreRule` supplémentaire (voir `docs/DATA_MODEL.md`).
Padel/Tennis de table/Badminton réutiliseront la même famille de moteur
quand ils seront implémentés — pas construits dans cette phase.

Nuances encore non résolues pour les presets restants :

1. **Volleyball — cible variable par set.** Le set décisif se joue à 15
   points au lieu de 25. `TARGET_SCORE` doit accepter une **cible qui
   dépend de l'index du set en cours** (ex: `targetScore: 25`,
   `finalSetTargetScore: 15`), pas une cible unique pour tout le match.
2. **Badminton — plafond de marge.** `WIN_BY` (marge 2) doit accepter un
   **plafond absolu** (30 points) au-delà duquel un seul point suffit à
   gagner, même sans marge de 2. (Badminton et Tennis de table ont aussi
   des sets — à évaluer au moment de leur implémentation s'ils doivent
   plutôt rejoindre le Racket Engine, comme Tennis, ou rester sur
   `ScoreRule` + une extension `SETS`/`BEST_OF` dédiée : pas encore
   tranché.)

Ces points sont à concevoir au moment de l'implémentation de chaque
sport, pas avant — ils ne remettent pas en cause le modèle générique,
seulement son paramétrage.

## Ajout d'un nouveau sport (V2+)

Avant d'ajouter un sport hors de cette liste :

1. Identifier quel(s) mode(s) `ScoreRule` existants le couvrent (voir
   `playtap-score-engine`). Ne créer un nouveau mode `ScoreRule` qu'en
   dernier recours, avec justification explicite.
2. Définir clairement le rapport joueurs → teams de scoring, comme
   ci-dessus, avant toute implémentation.
3. Vérifier s'il s'agit réellement d'un sport à score, ou plutôt d'un
   Timer/Interval/Workout preset (ex: "course à pied chronométrée" n'est
   pas un sport à score, c'est un Timer Engine preset).
