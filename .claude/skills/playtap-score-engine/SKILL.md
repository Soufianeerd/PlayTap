---
name: playtap-score-engine
description: Modèle générique du moteur de score PlayTap (ScoreRule, Competitor, Team, ScoreState, SetState, MatchState, ScoreEvent) pour tous les sports à score. Utiliser lors de la conception ou modification de tout sport de la catégorie Scores.
---

# PlayTap — Score Engine

## Principe

Un seul moteur de score générique, paramétré par sport via `ScoreRule`.
Aucun sport ne doit avoir sa propre logique de score dupliquée.

**Exception délibérée — sports de raquette (Tennis, et plus tard Padel/
Tennis de table/Badminton) : un second moteur générique, le Racket
Engine (`RacketMatchRule`/`RacketEngine`), pas un mode `ScoreRule`.**
Leur hiérarchie point → jeu → set → match ne peut pas s'exprimer dans le
réducteur plat de `ScoreEngine` (`Map<String, int>`) sans que celui-ci
devienne un second moteur déguisé — voir docs/DATA_MODEL.md
"RacketMatchRule" pour la justification complète et
`domain/engines/racket_engine.dart`. Padel et Tennis partagent la même
famille de règles Racket Engine ; seuls les paramètres changent (comme
`ScoreRule` pour tout le reste).

## Modèle conceptuel

```
Competitor        — un joueur individuel (nom, id)
Team               — un groupe de Competitors qui score ensemble
                      (ex: Padel double = 2 Competitors dans 1 Team)
ScoreRule          — configuration déclarative des règles de scoring
                      (porte un champ schemaVersion — voir DATA_MODEL.md)
ScoreEvent         — un événement atomique et immuable (point marqué,
                      correction, undo)
ScoreState         — état courant dérivé du replay des ScoreEvents
SetState           — état d'un set/manche (si le sport a des sets)
MatchState         — état global du match (sets/games/score courant,
                      vainqueur, terminé ou non)
```

`ScoreState` (et par extension `SetState`/`MatchState`) ne doit **jamais**
être muté directement. Il est toujours dérivé en rejouant la liste des
`ScoreEvent` depuis le début (event sourcing). C'est ce qui rend l'undo et
la reprise de session triviaux et fiables.

## ScoreRule — types de scoring à supporter

| Mode | Description | Exemples |
|---|---|---|
| `TARGET_SCORE` | Premier à N points gagne | Tennis de table (11), Badminton (21) |
| `FREE_SCORE` | Compteur libre sans fin définie | Score libre, pétanque en mode libre |
| `SEQUENTIAL_SCORE` | Séquence de scoring non numérique | Non implémenté — Tennis n'utilise plus ce mode, voir Racket Engine ci-dessus |
| `SETS` | Le match se joue en plusieurs manches | Volleyball, Tennis de table (Tennis utilise `SetRule`/Racket Engine, pas ce mode) |
| `BEST_OF` | Nombre de sets à gagner pour remporter le match | Best of 3, Best of 5 |
| `WIN_BY` | Écart minimum requis pour gagner | Win by 2 (volleyball, ping-pong) |
| `TEAM_SCORE` | Scoring par équipe avec incréments variables | Basketball (1/2/3), Football (1 par but) |

Un sport combine plusieurs de ces modes. Exemple :
- **Basketball** = `TEAM_SCORE` avec incréments {1, 2, 3}, pas de sets
- **Tennis** (Racket Engine, pas `ScoreRule`) = `GameScoringRule` (0/15/30/
  40, deuce/avantage ou No-Ad) + `SetRule` (6 jeux, tie-break optionnel) +
  `MatchFormatRule` (Best of N, set décisif classique ou Match Tie-break)
- **Pétanque** = `TARGET_SCORE` (13) + `TEAM_SCORE`

## Règles obligatoires

### Undo obligatoire

Chaque action de scoring doit pouvoir être annulée. Techniquement : retirer
le dernier `ScoreEvent` et re-dériver le `ScoreState` par replay. Ne jamais
implémenter un undo qui décrémente un compteur à la main — cela désynchronise
l'event log de l'état affiché.

### Event history obligatoire

Tous les `ScoreEvent` sont conservés (pas seulement l'état final). C'est la
source de vérité pour :
- l'historique/replay d'un match,
- la synchronisation phone/watch (`playtap-watch-sync`),
- la persistance offline (`playtap-offline-first`).

### Déterminisme

`ScoreState = reduce(ScoreEvents, ScoreRule)` doit être une fonction pure et
déterministe : mêmes events + mêmes règles → même état, toujours. Aucune
dépendance à l'horloge système, au réseau, ou à un ordre non garanti dans le
calcul de l'état.

### Tests déterministes obligatoires

Chaque `ScoreRule` supportée doit avoir des tests qui rejouent une séquence
fixe de `ScoreEvent` et vérifient le `MatchState` final (score, vainqueur,
set en cours) sans dépendance temporelle ni I/O. Inclure au minimum : cas
nominal, cas undo, cas égalité/deuce, cas fin de match.

Ces cas doivent être exprimés comme fixtures dans `/contracts/score`
(voir `docs/CONFORMANCE.md`) dès qu'un cas engage plusieurs plateformes
(Dart/Swift/Kotlin) — pas seulement comme tests unitaires internes à une
seule implémentation.

## Ne pas mélanger joueurs et sides de scoring

Voir `playtap-sports-rules` pour le détail par sport — mais règle générale :
le nombre de `Competitor` n'est pas le nombre de `Team`. Padel à 4 joueurs =
2 Teams de scoring, chaque Team contenant 2 Competitors.
