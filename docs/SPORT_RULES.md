# PlayTap — Sport Rules

> Le détail complet des presets V1 (Tennis, Padel, Tennis de table,
> Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score
> libre), avec le mapping joueurs/teams et les modes `ScoreRule` utilisés,
> vit dans le skill **`playtap-sports-rules`** — source de vérité unique,
> non dupliquée ici pour éviter toute divergence.

## Résumé rapide

| Sport | Teams de scoring | Modes ScoreRule |
|---|---|---|
| Tennis | 2 | SEQUENTIAL_SCORE, SETS, BEST_OF, WIN_BY |
| Padel | 2 | SEQUENTIAL_SCORE, SETS, BEST_OF |
| Tennis de table | 2 | TARGET_SCORE, WIN_BY, SETS, BEST_OF |
| Badminton | 2 | TARGET_SCORE, WIN_BY, SETS |
| Pétanque | 2 | TARGET_SCORE, TEAM_SCORE |
| Basketball | 2 | TEAM_SCORE |
| Football/Futsal | 2 | TEAM_SCORE |
| Volleyball | 2 | TARGET_SCORE, WIN_BY, SETS, BEST_OF |
| Score libre | 1..N | FREE_SCORE |

Règle absolue à retenir : **le nombre de joueurs n'est jamais égal au
nombre de teams de scoring par défaut** (ex : Padel = 4 joueurs, 2 teams).
Détail complet, y compris la procédure d'ajout d'un nouveau sport :
`.claude/skills/playtap-sports-rules/SKILL.md`.
