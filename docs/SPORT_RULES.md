# PlayTap — Sport Rules

> Le détail complet des presets V1 (Tennis, Padel, Tennis de table,
> Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score
> libre), avec le mapping joueurs/teams et les modes `ScoreRule` utilisés,
> vit dans le skill **`playtap-sports-rules`** — source de vérité unique,
> non dupliquée ici pour éviter toute divergence.

## Résumé rapide

| Sport | Teams de scoring | Modes ScoreRule | Statut |
|---|---|---|---|
| Tennis | 2 | Racket Engine (`RacketMatchRule` — point/jeu/set/match, hors `ScoreRule`) | **IMPLEMENTED** |
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
nouveau mode `ScoreRule` n'a été nécessaire.

Tennis (Racket Core Phase 1) est le premier Sport Pack complet construit
sur le **Racket Engine** générique (point → jeu → set → match, tie-break,
rotation de service — voir `docs/ARCHITECTURE.md` et `RacketMatchRule`
dans `docs/DATA_MODEL.md`) : un moteur entièrement nouveau, pas une
extension de `ScoreRule`, car la hiérarchie point/jeu/set/match ne peut
pas s'exprimer dans le réducteur plat de `ScoreEngine`. Padel/Tennis de
table/Badminton pourront réutiliser la même famille de moteur plus tard
(non implémenté dans cette phase, voir CLAUDE.md).

Périmètre v1 explicite (Phase Sports 2) :

- Score + périodes + clock + overtime + shootout (Football/Futsal) : **IMPLEMENTED**.
- Temps additionnel (Football/Futsal) : annonce manuelle (+X min), jamais
  calculé automatiquement (Law 7 — c'est une décision d'arbitre) : **IMPLEMENTED**.
- Shot clock (Basketball, 24/14 secondes) : **IMPLEMENTED** (Phase Sports
  2B) — `ShotClockEngine`, générique, réutilise `ClockAccumulator`.
- Temps morts (Basketball, Futsal) : **IMPLEMENTED** (Phase Sports 2B) —
  `TimeoutEngine`, une seule abstraction générique pour les deux sports
  (groupement par demi-terrain pour Basketball, par période pour Futsal).
- Fautes d'équipe / bonus (Basketball) et fautes cumulées (Futsal,
  "accumulated fouls") : **IMPLEMENTED** (Phase Sports 2B) —
  `TeamFoulEngine`, une seule abstraction générique réutilisée par les deux
  sports (seul le seuil diffère : 5 pour Basketball, 6 pour Futsal/DFKSAF).
- Fautes de joueur individuelles, feuille de match complète,
  remplacements : **NOT IMPLEMENTED** (hors périmètre — PlayTap reste un
  outil de score/match control, pas une feuille officielle de table de
  marque).

`MatchRule.shotClockRule`/`timeoutRule`/`teamFoulRule` sont tous les trois
optionnels (`null` = le sport ne les utilise pas — Football n'a aucun des
trois) ; leur ajout a été strictement additif, aucun bump de
`schemaVersion`.

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
- Article 29 (Shot clock) : 24 secondes standard ; reset à 14 secondes
  uniquement après un rebond offensif d'un tir raté ayant touché l'anneau,
  une faute de contact défensive juste après un tel tir raté, ou une
  remise en jeu offensive juste après. PlayTap ne devine jamais lequel de
  ces cas s'applique (`ShotClockRule` : deux boutons rapides "24"/"14",
  l'arbitre/marqueur décide). **IMPLEMENTED**.
- Article 18 (Time-out) : 2 temps morts en 1re mi-temps, 3 en 2e (max 2
  utilisables une fois l'horloge du Q4 ≤ 2:00 — `TimeoutLateGameSubCap`),
  1 par prolongation, jamais reporté d'une période à l'autre.
  **IMPLEMENTED**.
- Article 41 (Team fouls) : bonus à partir de la 5e faute d'équipe par
  quart-temps ; remise à zéro à chaque quart-temps réglementaire ; les
  fautes de prolongation sont comptées comme des fautes du Q4 (jamais
  remises à zéro en entrant en prolongation — vérifié directement dans
  Article 41.1.3). **IMPLEMENTED**.

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
- Temps mort : 1 par équipe par période (chaque période son propre quota,
  jamais reporté à l'autre période), aucun en prolongation. **IMPLEMENTED**
  — même `TimeoutRule`/`TimeoutEngine` générique que Basketball, seule la
  donnée de groupement diffère (par période ici, par demi-terrain pour
  Basketball).
- Fautes cumulées : à partir de la 6e faute d'équipe cumulée dans une
  période, coup franc direct sans mur (ou penalty si la faute est dans la
  surface) ; remise à zéro au début de la 2e période ; les fautes
  cumulées de la 2e période sont ensuite reportées en prolongation
  (jamais remises à zéro en entrant en prolongation). **IMPLEMENTED** —
  même `TeamFoulRule`/`TeamFoulEngine` générique que le bonus Basketball,
  seul le seuil diffère (6 au lieu de 5) ; le même comportement
  remise-à-zéro-par-période / report-en-prolongation, vérifié identique
  pour les deux sports, vit dans le moteur, pas dans la donnée. Un
  changement de règle 2025-26 exclut désormais les fautes sanctionnées
  par un penalty du comptage cumulé (seules celles sanctionnées par un
  coup franc direct comptent) — PlayTap ne fait **pas** cette distinction
  (un seul bouton générique "ajouter une faute d'équipe", jamais de
  détection automatique du type de faute) : c'est une simplification
  déclarée, pas une application littérale de la règle 2025-26 — à noter
  explicitement si une distinction plus fine est ajoutée plus tard.
- Prolongation/tirs au but : même format que le football (2×5 min de
  prolongation par bloc, tirs au but identiques à `ShootoutRule`).

## Tennis — source officielle

Source : International Tennis Federation (ITF), *Rules of Tennis 2026* —
https://www.itftennis.com/en/about-us/governance/rules-and-regulations/.
`rulesetId` persisté : `tennis.itf.2026` (voir
`mobile/lib/domain/rulesets/tennis_rulesets.dart`). Aucune édition 2027
n'existe à ce jour ; `rulesetId` reste préparé pour un futur changement de
règles sans jamais rejouer différemment une session déjà démarrée (voir
`docs/DATA_MODEL.md`, note sur `RacketMatchRule.rulesetId`).

- **Rule 4 (Score in a Game)** : 0/15/30/40, deuce/avantage — méthode
  standard (`AdvantageMode.advantage`). Méthode alternative officielle
  **No-Ad** (`AdvantageMode.noAd`) : à 40-40 ("deciding point"), le point
  suivant décide le jeu, jamais d'état "avantage". **IMPLEMENTED** — les
  deux méthodes partagent une seule formule de victoire
  (`points >= 4 && (points - adversaire) >= marginNeeded`, marge 1 en
  No-Ad, 2 en Advantage), voir `RacketEngine`.
- **Rule 5 (Score in a Set)** : premier à 6 jeux, écart de 2 ; tie-break à
  6-6 (méthode standard, `SetRule.tieBreak` présent). La variante "set à
  l'avantage" (jamais de tie-break, `SetRule.tieBreak` absent) est
  supportée par le moteur mais **non exposée** dans l'écran de
  configuration V1 — voir CLAUDE.md brief section 6.
- **Tie-break (Rule 5)** : premier à 7 points, écart de 2, sans plafond
  (8-6, 14-12...). **IMPLEMENTED**.
- **Match Tie-break** (variante officielle remplaçant le set décisif dans
  certaines compétitions) : premier à 10 points, écart de 2, sans
  plafond. Distinct d'un tie-break de set (`RacketMatchState.
  isMatchTieBreak` vs `isTieBreak`), jamais confondus. **IMPLEMENTED**.
- **Rule 5 (Score in a Match)** : l'écran V1 propose uniquement **Best of
  3** (2 sets gagnants) — le moteur ne suppose jamais ce nombre
  (`MatchFormatRule.setsToWin`), Best of 5 est déjà supporté par
  l'architecture, seulement pas exposé dans l'UI V1.
- **Rule 15 (Order of Service) / Rule 16 (doubles)** : le serveur change à
  chaque jeu complété (un tie-break comptant pour un jeu), en continu à
  travers les sets, jamais réinitialisé à un changement de set. En
  double, l'ordre des 4 joueurs est fixé une fois à la création de la
  session (le côté qui commence, choisi par l'utilisateur ; l'ordre au
  sein de chaque équipe suit l'ordre du roster) et persisté en entier —
  **IMPLEMENTED**.
- **Rotation de service au tie-break** : le joueur dont c'est le tour sert
  le premier point seul, puis le service alterne par blocs de 2 points
  (points 2-3, 4-5, 6-7...) — vérifié point par point dans les tests, pas
  approximé comme une alternance simple par point (CLAUDE.md brief
  section 13). **IMPLEMENTED**.
- **Rule 6 (Changement de côté)** : indicateur non-bloquant
  (`RacketMatchState.changeEndsDue`) — jamais une étape obligatoire de
  l'UI. Calcul simplifié documenté sur le champ lui-même (parité du
  nombre total de jeux joués hors tie-break ; multiple positif de 6
  points pendant un tie-break) — non une modélisation exhaustive de
  toutes les subtilités de la Rule 6 aux limites de set, une décision
  volontaire puisque CLAUDE.md n'exige qu'un indicateur, pas un blocage.
  **IMPLEMENTED** (indicateur uniquement).
- **Simple / Double** : toujours 2 sides de scoring (`side_a`/`side_b`),
  1 ou 2 joueurs par side (`ScoringSide.players`) — voir
  `playtap-sports-rules`. **IMPLEMENTED**.
- **Undo/recovery** : annule un point ; `RacketEngine.replay` re-simule
  entièrement la machine à états point/jeu/set/match sur la liste
  d'events survivante (pas une décrémentation), ce qui rouvre
  correctement un jeu/set/match tout juste terminé — voir
  `docs/DATA_MODEL.md`. **IMPLEMENTED**.
- **Feuille de match complète, classement, warm-up officiel chronométré** :
  **NOT IMPLEMENTED** (hors périmètre — PlayTap reste un outil de score,
  pas une feuille d'arbitre officielle).

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
