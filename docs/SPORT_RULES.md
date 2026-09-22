# PlayTap — Sport Rules

> Le détail complet des presets V1 (Tennis, Padel, Tennis de table,
> Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score
> libre), avec le mapping joueurs/teams et les modes `ScoreRule` utilisés,
> vit dans le skill **`playtap-sports-rules`** — source de vérité unique,
> non dupliquée ici pour éviter toute divergence.

## Résumé rapide

| Sport | Teams de scoring | Modes ScoreRule | Statut |
|---|---|---|---|
| Tennis | 2 | SEQUENTIAL_SCORE, SETS, BEST_OF, WIN_BY | NOT IMPLEMENTED |
| Padel | 2 | SEQUENTIAL_SCORE, SETS, BEST_OF | NOT IMPLEMENTED |
| Tennis de table | 2 | TARGET_SCORE, WIN_BY, SETS, BEST_OF | NOT IMPLEMENTED (SETS/BEST_OF manquants) |
| Badminton | 2 | TARGET_SCORE, WIN_BY, SETS | NOT IMPLEMENTED (SETS manquant) |
| Pétanque | 2 | TARGET_SCORE, TEAM_SCORE | **IMPLEMENTED** |
| Basketball | 2 | TEAM_SCORE | NOT IMPLEMENTED (preset non ajouté — le moteur TEAM_SCORE générique, lui, existe déjà) |
| Football/Futsal | 2 | TEAM_SCORE | NOT IMPLEMENTED (idem) |
| Volleyball | 2 | TARGET_SCORE, WIN_BY, SETS, BEST_OF | NOT IMPLEMENTED (SETS/BEST_OF manquants) |
| Score libre | 1..N | FREE_SCORE | **IMPLEMENTED** |

Règle absolue à retenir : **le nombre de joueurs n'est jamais égal au
nombre de teams de scoring par défaut** (ex : Padel = 4 joueurs, 2 teams).
Détail complet, y compris la procédure d'ajout d'un nouveau sport :
`.claude/skills/playtap-sports-rules/SKILL.md`.

Pétanque est le premier Sport Pack complet de bout en bout (Score Engine
générique TARGET_SCORE + TEAM_SCORE composés, UI, historique, contrats de
conformité) — voir `docs/DATA_MODEL.md` pour le choix architectural de
composition et `docs/CONFORMANCE.md`/`contracts/score/petanque_*.json`
pour les fixtures. Basketball et Football/Futsal sont déjà entièrement
exprimables avec le TEAM_SCORE générique existant (pas de nouveau mode
requis) mais n'ont pas encore de preset/UI dédiés.

## Pétanque — source officielle

Source : Fédération Internationale de Pétanque et Jeu Provençal (FIPJP),
*Official Rules for the Sport of Pétanque*. Point 2026 : la FIPJP indique
qu'aucune modification du règlement de jeu n'a été décidée pour 2026 et
qu'une éventuelle modification ne pourrait prendre effet qu'au 1er janvier
2027 — les règles ci-dessous restent donc la référence en vigueur.

**Article 1 — boules par joueur** (nombre de boules jouées par joueur
pendant une mène, donc plafond de points qu'un side peut marquer en une
seule mène = joueurs × boules/joueur) :

| Format | Joueurs par side | Boules par joueur | Plafond par mène |
|---|---|---|---|
| Individuel (tête-à-tête) | 1 | 3 | **3** |
| Doublette | 2 | 3 | 6 |
| Triplette | 3 | 2 | 6 |

C'est pourquoi `PetanqueFormat.allowedIncrements` (voir
`features/score_petanque/petanque_format.dart`) restreint tête-à-tête à
`[1, 2, 3]` et laisse doublette/triplette à `[1, 2, 3, 4, 5, 6]` — la
règle réellement persistée dans `TeamScoreRule.allowedIncrements` doit
toujours refléter ce plafond par format, jamais une valeur fixe `[1..6]`
appliquée à l'aveugle (bug corrigé le 2026-09-22, voir ROADMAP.md).

**Article 5 — cible** : une partie se joue normalement à 13 points ; des
poules/cadrages peuvent se jouer à 11 points. PlayTap V1 implémente
uniquement la cible **13** (`ScoreTarget(targetScore: 13)`). La variante à
**11 points n'est pas implémentée** — elle n'est documentée ici que comme
variante officielle future, non exposée dans l'UI ni configurable
actuellement. Ne pas prétendre que PlayTap couvre la variante 11 tant
qu'aucune UI/aucun paramètre ne permet réellement de la choisir.
