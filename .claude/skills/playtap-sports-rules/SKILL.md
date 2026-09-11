---
name: playtap-sports-rules
description: Presets sportifs V1 de PlayTap (Tennis, Padel, Tennis de table, Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score libre) exprimés comme configurations du Score Engine. Utiliser lors de l'ajout ou la modification d'un sport.
---

# PlayTap — Sports Rules (presets V1)

Chaque sport ci-dessous est un preset de `ScoreRule` (voir
`playtap-score-engine`) — jamais une implémentation séparée.

## Règle absolue : joueurs ≠ sides de scoring

Ne jamais mélanger le **nombre de `Competitor`** (joueurs physiques) et le
**nombre de `Team`** (entités qui marquent des points). Exemple canonique :

> **Padel à 4 joueurs = 2 équipes de score.**

Chaque sport ci-dessous précise explicitement les deux.

## Presets V1

### Tennis
- Joueurs : 2 (simple) ou 4 (double) → Teams de scoring : toujours 2
- Scoring : `SEQUENTIAL_SCORE` (0/15/30/40/Game) + `SETS` + `BEST_OF`
  (3 ou 5) + `WIN_BY` (deuce à 40-40, tie-break configurable)

### Padel
- Joueurs : 4 (toujours double) → Teams de scoring : 2 (2 joueurs/team)
- Scoring : identique à Tennis (`SEQUENTIAL_SCORE` + `SETS` + `BEST_OF`),
  avec règle golden point configurable (pas de deuce)

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

## Points d'extension `ScoreRule` identifiés (à traiter en Phase 1, pas avant)

Les 9 presets V1 sont tous exprimables avec les modes `ScoreRule`
existants (voir `playtap-score-engine`). Trois nuances demandent
cependant une petite extension de `ScoreRule` avant l'implémentation —
aucune ne justifie un nouveau mode, toutes s'ajoutent comme paramètres
optionnels aux modes existants :

1. **Tennis/Padel — tie-break.** À 6-6 jeux, le jeu décisif se joue en
   points bruts (0,1,2...7, `WIN_BY` 2) et non avec les labels
   `SEQUENTIAL_SCORE` (0/15/30/40). `ScoreRule` doit pouvoir décrire un
   **sous-mode conditionnel** activé à une condition de `SetState`
   (jeux à 6-6) plutôt qu'un mode unique et fixe pour tout le match.
2. **Volleyball — cible variable par set.** Le set décisif se joue à 15
   points au lieu de 25. `TARGET_SCORE` doit accepter une **cible qui
   dépend de l'index du set en cours** (ex: `targetScore: 25`,
   `finalSetTargetScore: 15`), pas une cible unique pour tout le match.
3. **Badminton — plafond de marge.** `WIN_BY` (marge 2) doit accepter un
   **plafond absolu** (30 points) au-delà duquel un seul point suffit à
   gagner, même sans marge de 2.

Ces trois points sont à concevoir au moment de l'implémentation du Score
Engine (Phase 1), pas en Phase 0 — ils ne remettent pas en cause le
modèle générique, seulement son paramétrage.

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
