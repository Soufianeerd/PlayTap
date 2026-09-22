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
