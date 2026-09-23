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
| Basketball | 2 | TEAM_SCORE + MatchRule (périodes/clock/overtime) | **IMPLEMENTED** |
| Football | 2 | TEAM_SCORE + MatchRule (+ shootout optionnel) | **IMPLEMENTED** |
| Futsal | 2 | TEAM_SCORE + MatchRule (+ shootout optionnel) | **IMPLEMENTED** |
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
pour les fixtures.

Basketball/Football/Futsal (Phase Sports 2) sont le premier Sport Pack
complet construit sur le **Match Engine** générique (périodes/clock/
overtime/shootout, voir `docs/ARCHITECTURE.md` et `MatchRule` dans
`docs/DATA_MODEL.md`), composé avec le TEAM_SCORE existant — aucun
nouveau mode `ScoreRule` n'a été nécessaire. Périmètre v1 explicite :

- Score + périodes + clock + overtime + shootout (Football/Futsal) : **IMPLEMENTED**.
- Temps additionnel (Football/Futsal) : annonce manuelle (+X min), jamais
  calculé automatiquement (Law 7 — c'est une décision d'arbitre) : **IMPLEMENTED**.
- Temps morts (timeouts) : **NOT IMPLEMENTED** (v1 — décision de scope
  explicite, voir la justification ci-dessous).
- Fautes cumulées (Futsal, "accumulated fouls") : **NOT IMPLEMENTED** (v1).
- Fautes d'équipe / bonus (Basketball) : **NOT IMPLEMENTED** (v1).

Ces trois fonctionnalités sont volontairement différées à une phase
ultérieure : chacune ajouterait un nouveau type d'event, un nouvel état,
une nouvelle surface UI et de nouvelles fixtures pour une fonctionnalité
qui ne contribue pas à prouver le moteur générique — alors que la
priorité explicite de cette phase est que score + périodes + clock +
overtime soient irréprochables. `MatchRule` ne déclare simplement pas ces
champs en v1 ; les ajouter plus tard sera additif (pas de bump de
`schemaVersion`).

### Basketball — source officielle

FIBA *Official Basketball Rules*. Au 2026-09-23 : l'édition **2024**
("Valid as of 1st October 2024") est en vigueur ; l'édition **2026**
devient effective le **2026-10-01**. Aucune différence trouvée entre les
deux éditions sur la structure période/clock/score/timeout/faute — les
deux rulesets persistés (`basketball.fiba.2024` / `basketball.fiba.2026`,
voir `mobile/lib/domain/rulesets/basketball_rulesets.dart`) ne diffèrent
donc que par leur identifiant, jamais par leurs valeurs (règle "ne pas
dupliquer des valeurs identiques").

- Article 8 (Playing time, tied score, overtime) : 4 quart-temps × 10
  minutes ; égalité à la fin du Q4 → prolongations de 5 minutes, autant
  que nécessaire (jamais de match nul).
- Article 16 (Goal value) : lancer franc = 1, panier zone à 2 points = 2,
  panier zone à 3 points = 3.
- Article 18 (Time-out) : 2 temps morts en 1re mi-temps, 3 en 2e (max 2
  une fois l'horloge du Q4 ≤ 2:00), 1 par prolongation. **NOT
  IMPLEMENTED** en v1 (voir périmètre ci-dessus).
- Article 41 (Team fouls) : bonus à partir de la 5e faute d'équipe par
  quart-temps. **NOT IMPLEMENTED** en v1.

Session persistée avant le 2026-10-01 → `basketball.fiba.2024` pour
toujours, même après que l'app bascule sur l'édition 2026 par défaut
(règle absolue : le `MatchRule` résolu est persisté en entier dans
`SESSION_STARTED`, jamais recalculé plus tard).

### Football — source officielle

IFAB *Laws of the Game 2026/27*, en vigueur depuis le 2026-07-01
(`football.ifab.2026_27`).

- Law 7 (Duration of the Match) : 2 mi-temps égales de 45 minutes, clock
  qui tourne (RUNNING_CLOCK) ; le temps additionnel est à la discrétion de
  l'arbitre — PlayTap ne l'invente jamais automatiquement, il est annoncé
  manuellement (`ADDED_TIME_ANNOUNCED`, purement informatif : le clock
  continue de tourner librement quoi qu'il arrive).
- Prolongation (extra time) : format usuel 2×15 minutes — c'est une règle
  de **compétition**, pas une obligation IFAB pour tout match ; modélisée
  comme un bloc de durée fixe (`OvertimeRule.maxCount: 2`) toujours joué
  intégralement, même si le score se décide avant la fin du 2e quart
  d'heure (voir la double sémantique documentée sur `OvertimeRule.
  maxCount`).
- Tirs au but (kicks from the penalty mark) : 5 tirs alternés par équipe,
  arrêt anticipé dès que le résultat est mathématiquement joué, puis mort
  subite un tir chacun. Score des tirs au but jamais fusionné au score du
  match (résumé : "1–1, Tirs au but 4–3").

Format Championnat (`league`) : match nul autorisé, pas de prolongation
ni de tirs au but. Format Élimination directe (`knockout`) : jamais de
match nul, prolongation puis tirs au but si toujours à égalité.

### Futsal — source officielle

FIFA *Futsal Laws of the Game* — dernière édition **vérifiée** au moment
de l'écriture : **2025-26** (effective 2025-07-01), `futsal.fifa.2025_26`.
**Non vérifié** : l'existence d'une édition 2026-27 spécifique au futsal
n'a pas pu être confirmée ni infirmée — à re-vérifier sur le hub digital
FIFA avant de considérer cette section comme définitive.

- Law 7 (Duration of the Match) : 2 périodes égales de 20 minutes, clock
  arrêté (STOPPED_CLOCK).
- Temps mort : 1 par équipe par période, non reporté à l'autre période,
  aucun en prolongation. **NOT IMPLEMENTED** en v1.
- Fautes cumulées : à partir de la 6e faute d'équipe cumulée dans une
  période, coup franc direct sans mur (ou penalty si la faute est dans la
  surface) ; les fautes cumulées de la 2e période sont reportées en
  prolongation (jamais remises à zéro). Un changement de règle 2025-26
  exclut désormais les fautes sanctionnées par un penalty du comptage
  cumulé (seules les fautes sanctionnées par un coup franc direct
  comptent). **NOT IMPLEMENTED** en v1 — voir le périmètre ci-dessus ; si
  un compteur simplifié est ajouté plus tard sans cette distinction
  penalty/coup-franc, le documenter explicitement comme une
  simplification déclarée, jamais comme une application littérale de la
  règle 2025-26.
- Prolongation/tirs au but : même format que le football (2×5 min de
  prolongation par bloc, tirs au but identiques à `ShootoutRule`).

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
