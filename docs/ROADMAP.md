# PlayTap — Roadmap

## Phase 0 — Fondations (statut : durci, prêt pour Phase 1)

- [x] Workspace, `CLAUDE.md`, skills métier, documentation (phase 0.1).
- [x] Dépôt Git local isolé pour PlayTap + règle anti-mutation du dépôt
      parent (voir `CLAUDE.md` — "Repository parent").
- [x] Contrats multi-plateformes `/contracts` + fixtures de référence
      Score/Timer/Interval + `docs/CONFORMANCE.md` (phase 0.2, hardening).
- [x] `schemaVersion` sur Preset/ScoreRule/TimerSpec/IntervalProgram/
      WorkoutSequence/Session sync payload (voir `docs/DATA_MODEL.md`).
- [x] Event ordering (`originSequence`) et modèle temporel
      (monotonic vs wall-clock) documentés.
- [x] `docs/RELEASE_0_1.md` — premier vertical slice défini.

## Phase 1A — Scaffolding exécutable & toolchain (statut : fait, avec blockers documentés)

- [x] Décision définitive de persistance mobile : SQLite via Drift (voir
      `docs/DATA_MODEL.md` — inclut le point d'attention `drift_dev`).
- [x] `/mobile` — vraie app Flutter (Riverpod, go_router, Drift), coque
      4 tabs (Accueil/Activités/Historique/Réglages), design tokens,
      `flutter analyze`/`test` verts, lancée réellement (Chrome web —
      seul target disponible sur cette machine, voir ci-dessous).
- [x] `/apple-watch` — source Swift/SwiftUI écrite (App + RootView +
      Info.plist + Assets.xcassets) ; **build non exécuté** : Xcode
      complet absent de cette machine (seulement Command Line Tools),
      confirmé par l'échec direct de `xcodebuild`/`xcrun simctl` et de
      XcodeBuildMCP. Voir `apple-watch/README.md`.
- [x] `/wear-os` — projet Kotlin + Compose for Wear OS Material3, wrapper
      Gradle généré, **`./gradlew assembleDebug` exécuté réellement avec
      succès** (APK debug produit). Aucun émulateur Wear OS local
      disponible pour un lancement runtime (aucune image système
      installée) ; fleet cloud Mobile MCP disponible mais non utilisée
      (nécessite une connexion explicite de l'utilisateur).
- [x] `/contracts/{score,timer,interval}` reserved test runner locations
      créées (`mobile/test/conformance`, `apple-watch/tests/conformance`,
      `wear-os/app/src/test/kotlin/.../conformance`) — vides, à peupler
      en Phase 1B.

## Phase 1B.1 — Score Libre Mobile (statut : fait)

Premier vertical slice métier de bout en bout — preuve que toute la
plomberie fondamentale (event sourcing, Drift, undo, recovery, history,
conformance) fonctionne avant d'ajouter des règles sportives complexes.

- [x] **Résolution `drift_dev`** : combinaison figée `drift 2.31.0` +
      `drift_dev 2.31.0` + `build_runner 2.15.1` + `analyzer 8.4.1`
      (voir `docs/DATA_MODEL.md` — "Résolution drift_dev"). Codegen
      (`dart run build_runner build`) fonctionne réellement.
- [x] Score Engine pur FREE_SCORE (`domain/engines/score_engine.dart`) +
      19 tests unitaires + fixture `/contracts/score/free_score_basic`
      passée réellement (les 3 autres fixtures — modes non implémentés —
      explicitement `skip`, jamais un faux succès).
- [x] Modèle domaine : `Session`/`SessionEvent`/`ScoreRule`(sealed,
      `FreeScoreRule`)/`ScoreState`/`ScoringSide`/`OriginDevice` —
      extensible vers TARGET_SCORE/SEQUENTIAL_SCORE/TEAM_SCORE/SETS/
      BEST_OF/WIN_BY sans réécriture.
- [x] Base Drift réelle (`AppDatabase`, tables `sessions`/`events`/
      `presets`, contrainte unique `(sessionId, originDevice,
      originSequence)`), repositories (`SessionRepository`,
      `EventRepository`), 12 tests DB réels (SQLite in-memory, pas de
      mocks) + recovery testée.
- [x] UI complète : Activités → Score → Score libre → config (2/3/4,
      noms modifiables) → Active Score Session (zones tactiles pleines,
      pulse ~150ms, haptic léger, undo AppBar, Terminer + confirmation)
      → Résumé → Historique (dérivé de Session+Events, pas de colonne
      `finalScore`). Home affiche "REPRENDRE LA PARTIE" si session active
      ; choix Reprendre/Abandonner si une nouvelle partie est demandée
      pendant qu'une autre est active.
- [x] 40 tests verts (`flutter test`), 3 skip explicites (modes non
      implémentés) — unitaires Score Engine, DB/repositories, conformance,
      4 flows widget (2/3/4 participants, reprise de session).
- [x] **Vérification runtime réelle sur émulateur Android** (AVD
      `playtap_test`, API 34, provisionné dans cette session) — Chrome
      web n'est plus un target valide dès que Drift/SQLite réel est
      présent (`dart:ffi` non supporté sur web, confirmé par un échec de
      compilation réel). Flow complet joué à la main (config → score →
      undo → fin → résumé → historique), puis test de recovery réel :
      `adb shell am force-stop` sur le process, relance à froid,
      score exact retrouvé, `originSequence` vérifié strictement croissant
      (1→10, aucun doublon) en lisant directement le fichier SQLite tiré
      du device.
- [x] Wear OS non-régressé (`./gradlew assembleDebug --offline` toujours
      vert).

## Phase 1B.2 — Timer Engine mobile (statut : fait — Chronomètre/Countdown/Lap Timer)

Deuxième vertical slice — Timer Engine générique (monotonic en exécution,
timestamps wall-clock pour la persistence — voir `playtap-timer-engine`),
et généralisation de l'invariant "une seule session active" à travers les
catégories (Score + Timer), sans dupliquer de mécanisme.

- [x] Timer Engine pur (`domain/engines/timer_engine.dart`) — Stopwatch,
      Countdown, Lap Timer (Interval réservé, non implémenté cette phase) :
      `replay()` (persistance) et `projectLiveElapsed()` (affichage live)
      partagent la même logique de clamp via `_finalize()`, garantissant
      qu'elles ne peuvent jamais diverger. `AppClock`/`SystemAppClock`/
      `FakeClock` (`core/time/app_clock.dart`) — horloge monotonic pour le
      ticker live, horloge murale pour tout ce qui est persisté.
      24 tests unitaires + 8 tests de conformité (`/contracts/timer/`:
      `countdown_basic`, `pause_resume`, `lap_timer_basic`) passés
      réellement.
- [x] Événements `TIMER_STARTED/PAUSED/RESUMED/LAP_RECORDED/TIMER_COMPLETED`
      ajoutés à `SessionEventType` ; aucun `TIMER_TICK` persisté (l'affichage
      live ne dérive jamais d'un événement, seulement de l'horloge
      monotonic + du dernier état persisté).
- [x] Persistence : réutilisation intégrale du schéma `Sessions`/`Events`/
      `Presets` existant — **aucune migration** (pas de v2 nécessaire),
      3 presets `TIMER` ajoutés au seed `onCreate`. 3 tests DB réels
      dédiés Timer (SQLite in-memory, pas de mocks) : round-trip du
      `TimerSpec` dans le payload `SESSION_STARTED`, séquence complète
      start/pause/resume/lap/complete rejouée correctement, et
      `originSequence` vérifié strictement croissant après un redémarrage
      simulé du process (nouvelle `AppDatabase` sur le même executor).
- [x] Généralisation "une seule session active" : `SessionRepository`
      (`getActiveSession`/`watchActiveSession`/`getCompletedSessions`) ne
      filtre plus par catégorie ; routing (`activeSessionRoute`) et dialog
      de conflit (`showActiveSessionConflictDialog`) déplacés dans
      `features/shared/` et partagés Score+Timer. Home affiche
      "REPRENDRE L'ACTIVITÉ" (au lieu de "...LA PARTIE") pour refléter
      la généricité.
- [x] UI complète des 3 modes : Activités → Timer → Chronomètre/Countdown
      (config durée)/Lap Timer → session active (affichage live ~200ms,
      pause/reprise, LAP pour Lap Timer, Terminer + confirmation) →
      Résumé → Historique (dérivé de Session+Events par catégorie, sealed
      `HistoryEntry`).
- [x] 79 tests verts (`flutter test`), 3 skip explicites inchangés
      (modes Score non implémentés) — unitaires Timer Engine, DB/
      repositories (Score + Timer), conformance Score + Timer, 4 flows
      widget Score (non-régression) + 4 flows widget Timer (Stopwatch
      pause/reprise/historique, Countdown auto-complétion, Lap Timer,
      reprise après redémarrage simulé avec horloge murale).
- [x] **Bug réel trouvé et corrigé par les tests** : le ticker live
      (`Timer.periodic` ~200ms) de la page de session active continuait
      d'appeler `setState` après la complétion, chaque rebuild
      re-planifiant une navigation `pushReplacement` concurrente avant
      que la précédente n'ait pu démonter la page — boucle
      auto-entretenue empêchant toute navigation réelle. Corrigé en
      annulant le ticker dès la détection de fin de session, et en
      unifiant la navigation sur ce seul point (suppression du
      `pushReplacement` explicite redondant dans le flux "Terminer"
      manuel). Repéré uniquement parce que les tests widget pompaient
      des frames réelles au lieu de `pumpAndSettle` — jamais vu à la main
      en usage ponctuel.
- [x] **Vérification runtime réelle sur émulateur Android** (AVD
      `playtap_test`, API 34, redémarré dans cette session) : app
      installée et lancée réellement (`flutter run`), flow Chronomètre
      joué à la main (démarrage, affichage live ~10 min de temps réel
      observé), navigation Home ↔ Activités ↔ Timer ↔ session ↔ Résumé
      ↔ Historique confirmée par de vrais taps, dialog de confirmation
      "Terminer" confirmé. **Test de recovery réel critique** :
      `adb shell am force-stop` sur le process pendant que le Chronomètre
      tournait, ~64s de temps réel écoulé process mort, relance à froid —
      l'élapsed a correctement intégré tout le temps mort via l'horloge
      murale (pas figé, pas remis à zéro), session toujours "REPRENDRE
      L'ACTIVITÉ" depuis Home, reprise exacte confirmée. Non-régression
      Score Libre vérifiée par la suite automatisée (FLOW 1-4 toujours
      verts) plutôt qu'à la main cette fois.
      Limitation notée honnêtement : la vérification manuelle par tap
      réel des boutons PAUSE/REPRENDRE/LAP/COMMENCER et de la
      complétion automatique du Countdown n'a pas pu être menée à bien
      sur cet AVD précis — les taps `adb shell input tap`/`swipe` dans
      une bande verticale spécifique de l'écran (~y 1450-1950px physiques)
      n'atteignaient jamais l'app quelle que soit la position horizontale
      ou la technique essayée (tap instantané, swipe de 300ms, device
      `touchscreen` explicite), alors que les taps en dehors de cette
      bande fonctionnaient de façon fiable. Cause non identifiée
      (probablement un artefact de ce test grandeur nature/AVD
      spécifique, pas un défaut de l'app) — ces interactions restent
      couvertes par les tests widget Flutter (taps précis par sémantique,
      pas par coordonnée) et par les tests unitaires/DB.
- [x] Wear OS non-régressé (`./gradlew assembleDebug --offline` toujours
      vert, `BUILD SUCCESSFUL`).
- [ ] Interval Engine (`playtap-interval-engine`), validé contre
      `/contracts/interval` — hors périmètre de cette phase.
- [ ] Workout Sequence Engine (`playtap-workout-engine`) — hors périmètre.
- [ ] Runners de conformité Swift/Kotlin (le runner Dart existe depuis
      la Phase 1B.1 — `mobile/test/conformance/`) exécutant les mêmes
      fixtures `/contracts` (voir `docs/CONFORMANCE.md`) — hors périmètre.
- [ ] Reste du Score Engine générique : SEQUENTIAL_SCORE, SETS, BEST_OF
      (voir points d'extension déjà identifiés dans `playtap-sports-rules`)
      — hors périmètre. TARGET_SCORE, TEAM_SCORE et WIN_BY sont faits (voir
      Phase Sports 1 ci-dessous).
- [ ] Apple Watch Timer, Wear OS Timer, synchronisation watch — hors
      périmètre (voir la politique Xcode/CI macOS différée dans
      `CLAUDE.md`/`docs/ARCHITECTURE.md`).

## Phase Sports 1 — TARGET_SCORE, TEAM_SCORE, Pétanque (statut : fait)

Fondation générique du Score Engine au-delà de FREE_SCORE, et premier
Sport Pack complet de bout en bout — voir `docs/DATA_MODEL.md` pour la
décision de composition TARGET_SCORE + TEAM_SCORE et
`docs/SPORT_RULES.md` pour le statut à jour par sport.

- [x] `TargetScoreRule` (schemaVersion, sideIds, targetScore,
      automaticCompletion, winBy optionnel) et `TeamScoreRule`
      (schemaVersion, sideIds, allowedIncrements, target `ScoreTarget`
      optionnel) — objet `ScoreTarget`/`ScoreWinBy` partagé et composable,
      pas un troisième sous-type scellé par combinaison.
- [x] `ScoreEngine._replayPointBased` — cœur de replay partagé par
      TARGET_SCORE et TEAM_SCORE (fin automatique au franchissement de la
      cible, marge WIN_BY optionnelle, undo qui rouvre le match si la mène
      annulée est celle qui l'avait terminé). `_replayFreeScore` inchangé
      (zéro régression FREE_SCORE).
- [x] `ScoreState.rounds` (liste de `ScoreRound`) — une mène Pétanque =
      un seul `POINT_SCORED`, pas de nouveau type d'event.
      `ScoringSide.players` optionnel pour les sides à plusieurs joueurs
      (doublette/triplette).
- [x] Pétanque de bout en bout sur mobile : Activités → Score → Pétanque
      → config (tête-à-tête/doublette/triplette, noms équipe + joueurs) →
      session active (score énorme par équipe, +1..+6 par mène, "Mène N",
      undo toujours actif) → fin automatique à 13+ → Résumé → Historique
      (libellé et compte de mènes dédiés) → abandon manuel. Score Libre
      non régressé (Home/Activités passent maintenant par
      `ScorePresetsPage` puisqu'il y a 2 presets, au lieu de sauter
      directement à sa config).
- [x] Persistence : preset `sport.petanque` seedé (id partagé via
      `domain/models/preset_ids.dart`, jamais dupliqué en dur),
      `SessionRepository.reopenSession` (undo qui rouvre un match
      auto-complété), routing par `presetRef` (Score Libre et Pétanque
      partagent `SessionCategory.score`).
- [x] Fixtures `/contracts/score` : `team_score_basic`, `petanque_basic`,
      `petanque_13_completion` (dépassement de 13 dans une mène — "13 ou
      plus", pas exactement 13), `petanque_undo`,
      `petanque_recovery_projection`. Fixture préexistante
      `target_score_win_by_two` (jamais exécutée avant, toujours `skip`)
      corrigée : sa séquence à 12 events ne pouvait pas mathématiquement
      atteindre son propre score final revendiqué (12-10) — étendue à 22
      events cohérents, mêmes valeurs finales.
- [x] 127 tests verts (`flutter test`), 2 skip explicites inchangés
      (SEQUENTIAL_SCORE toujours non implémenté) — unitaires Score Engine
      (TargetScoreRule/TeamScoreRule/composition Pétanque), DB/repositories
      (persistence, undo/reopen, reprise après redémarrage simulé),
      conformance, 4 flows widget Pétanque (doublette bout en bout,
      tête-à-tête/triplette config, abandon manuel) + non-régression Score
      Libre.
- [x] Localisation complète (11 langues) des nouvelles chaînes Pétanque ;
      RTL arabe non re-testé automatiquement au-delà de la couverture
      RTL générique déjà en place (`test/app/locale_test.dart`).
- [ ] Vérification runtime réelle sur émulateur/device Android — non
      effectuée cette phase (pas d'environnement Android disponible),
      voir le rapport de phase pour le détail. `flutter analyze`/`test`
      sont la seule vérification obtenue.

### Corrections post-revue (2026-09-22)

Revue du commit initial (`b5d5970`) sur `review/petanque-phase1` avant
merge dans `main` — deux bugs corrigés avant validation :

- [x] **Plafond par mène non respecté en tête-à-tête.** FIPJP Article 1 :
      tête-à-tête = 1 joueur × 3 boules = 3 boules max par mène, pas 6
      (voir la nouvelle section "Pétanque — source officielle" ci-dessus).
      `buildPetanqueRule()` prenait toujours `allowedIncrements: [1..6]`
      quel que soit le format, et l'UI active recalculait ses boutons
      `+1..+6` en dur plutôt que de les dériver de la `ScoreRule`
      persistée — deux sources de vérité. Corrigé : `PetanqueFormat.
      allowedIncrements` (tête-à-tête `[1,2,3]`, doublette/triplette
      `[1..6]`) alimente `buildPetanqueRule(format)`, et
      `ScoreSessionSnapshot` porte désormais la `ScoreRule` persistée
      elle-même — l'UI active lit `allowedIncrements` depuis là, jamais
      recalculée.
- [x] **Nom du joueur perdu en tête-à-tête.** `petanque_config_page.dart`
      collectait le nom du joueur puis le jetait
      (`players: format == headToHead ? null : players`). Corrigé : le
      roster complet (1, 2 ou 3 joueurs selon le format) est toujours
      persisté dans `ScoringSide.players`.
- [x] Format récupérable sans ambiguïté après persistence/recovery, sans
      migration DB ni `formatId` explicite : `PetanqueFormat.fromPersisted`
      reconstruit le format à partir du roster persisté (nombre de
      joueurs) + `TeamScoreRule.allowedIncrements`, tous deux déjà
      persistés dans `SESSION_STARTED`.
- [x] Tests ajoutés : `test/features/petanque_actions_test.dart` (10 tests
      — increments par format, rejet +4/+5/+6 en tête-à-tête,
      `fromPersisted` round-trip) + 5 nouveaux flows dans
      `test/petanque_widget_test.dart` (boutons affichés par format, nom
      du joueur tête-à-tête persisté et récupéré après redémarrage
      simulé). 141 tests verts, 2 skip inchangés, Free Score non régressé.
- [x] `docs/SPORT_RULES.md` mis en cohérence avec FIPJP Article 1 (boules
      par joueur, plafond par mène) et Article 5 (13 points = implémenté,
      11 points/poules-cadrages = variante officielle documentée mais non
      implémentée, jamais présentée comme couverte).

### Deuxième correction post-revue — Undo depuis le Résumé (2026-09-22)

Bug trouvé en revue sur le même commit : `PetanqueSessionController.
undoLast()` et `SessionRepository.reopenSession()` savaient déjà rouvrir
une partie auto-complétée, mais `ActivePetanqueSessionPage` navigue
immédiatement vers `PetanqueSummaryPage` dès que `matchComplete` devient
vrai — et le Résumé n'exposait aucun Undo. La capacité existait dans le
moteur/controller mais restait inaccessible à l'utilisateur.

- [x] `PetanqueSummaryPage` propose désormais une action secondaire
      "Annuler la dernière mène" (réutilise `l10n.undoLastRound`, déjà
      utilisé sur la barre Undo de la session active — sémantiquement
      identique). Au tap : appelle `undoLast()` sur le même controller
      (`petanqueSessionControllerProvider(sessionId)`, partagé avec la
      session active), relit l'état résultant, et si `matchComplete` est
      bien redevenu faux, `pushReplacement` vers `/score/petanque/session/
      $sessionId` — aucune logique de score dupliquée dans le Résumé.
      Bouton `OutlinedButton`, visuellement secondaire au `FilledButton`
      "Voir l'historique" qui reste l'action principale.
- [x] **Garde de concurrence ajoutée** (`_mutationInFlight` sur
      `PetanqueSessionController`, même forme que `TimerSessionController.
      _finalizeInFlight`) : un double-tap rapide sur le même bouton de
      mène — avant qu'aucun `await` ne se résolve — déclenchait deux
      `POINT_SCORED` pour ce que l'utilisateur perçoit comme un seul tap.
      Vérifié réel avant correction (test reproduit le double-tap sans
      `pumpAndSettle` entre les deux `tap()`), pas un refactor spéculatif.
- [x] Tests ajoutés : flow widget complet (12 → mène gagnante → Résumé →
      Undo → session active à 12, `status=ACTIVE`, `endedAt=null` → nouvelle
      mène gagnante → Résumé réapparaît, score/historique corrects, aucun
      doublon) + flow double-tap (une seule mène enregistrée) +
      test DB dédié `watchCompletedSessions` sur la transition COMPLETED →
      ACTIVE → COMPLETED (aucune entrée dupliquée à aucune étape). 144
      tests verts, 2 skip inchangés, Free Score non régressé.

## Phase Sports 2A — Basketball, Football, Futsal (statut : fait — score/périodes/clock/overtime/shootout ; timeouts/fautes cumulées différés à la Phase Sports 2B ci-dessous)

Basketball/Football/Futsal, construits sur un nouveau Match Engine
générique (périodes/clock running-vs-stopped/overtime/shootout) composé
avec le TEAM_SCORE existant — voir `docs/DATA_MODEL.md` "MatchRule" pour
l'architecture complète et `docs/SPORT_RULES.md` pour les sources
officielles (FIBA/IFAB/FIFA) et le périmètre v1 explicitement différé.

- [x] `ClockEngine`/`ClockAccumulator` extrait de `TimerEngine` (refactor
      pur, zéro changement de comportement — 144 tests existants +
      fixtures `contracts/timer/*` inchangés avant tout nouveau code).
- [x] `MatchEngine` (periodStarted/periodEnded/timerStarted/Paused/
      Resumed/Completed/addedTimeAnnounced/shootoutStarted/Completed/undo/
      sessionCompleted), `decideNextPhase` (fonction pure, data-driven,
      aucune branche par sport — gère les deux sémantiques de
      `OvertimeRule.maxCount`, illimité vs. bloc de longueur fixe).
- [x] `ShootoutEngine` générique (Football/Football), early clinch et mort
      subite calculés depuis `kicksPerRound`, jamais un "5" en dur ; undo
      via filtre-puis-rejoue, comme `MatchEngine`.
- [x] `SessionEventType` étendu (`PERIOD_STARTED`, `PERIOD_ENDED`,
      `ADDED_TIME_ANNOUNCED`, `SHOOTOUT_STARTED`, `SHOOTOUT_ATTEMPT`,
      `SHOOTOUT_COMPLETED`) ; `TIMER_STARTED`/`SESSION_STARTED`/
      `SESSION_COMPLETED`/`POINT_SCORED`/`UNDO` réutilisés sans changement.
- [x] Rulesets versionnés (`domain/rulesets/`) : `basketball.fiba.2024`/
      `2026` (bascule 2026-10-01, valeurs identiques — id seul diffère),
      `football.ifab.2026_27`, `futsal.fifa.2025_26` — résolus une seule
      fois à la création de session, persistés en entier dans
      `SESSION_STARTED`, jamais recalculés plus tard.
- [x] Scaffold UI partagé `features/score_team_match/` (actions,
      controller, page active, page résumé, panneau tirs au but) + config
      minces par sport (`score_basketball/`, `score_football/`,
      `score_futsal/`) ; routing (9 routes), liste de presets, résolution
      de reprise de session par `presetRef`.
- [x] Contrats de conformité : `contracts/match/*` (12 fixtures),
      `contracts/shootout/*` (4 fixtures), `contracts/score/
      basketball_scoring_123.json` + 2 nouveaux runners
      (`match_conformance_test.dart`, `shootout_conformance_test.dart`).
- [x] Tests : ~100 nouveaux tests (engines purs, rulesets, deriver, 2
      suites de flow widget bout-en-bout — Basketball config→score→clock→
      Q1-Q4→égalité→prolongation→décision→résumé ; Football clock qui
      tourne→temps additionnel→mi-temps manuelle→prolongation bloc
      fixe→tirs au but→nul/décision). 245 tests verts, 2 skip inchangés
      (SEQUENTIAL_SCORE, non lié à cette phase).
- [x] **Décision de scope** : temps morts, fautes cumulées (Futsal),
      fautes d'équipe/bonus (Basketball) explicitement différés à une
      phase ultérieure (voir la justification dans
      `docs/SPORT_RULES.md`) — `MatchRule` ne déclare pas ces champs en
      v1, les ajouter sera additif.
- [ ] Build/tests natifs iOS/watchOS — différé à l'environnement macOS
      CI/build (Xcode non installé localement, décision produit déjà
      prise — voir CLAUDE.md "Stratégie Apple").
- [ ] QA runtime Android/simulateur réel — non exécutée dans cette session
      (pas d'environnement mobile disponible) ; à faire avant release.

Bug trouvé pendant l'implémentation (corrigé avant tout test de flow) :
`MatchEngine.projectLiveElapsed` reconstruisait un `ClockAccumulator` sans
`runningSinceMs`, ce qui le faisait lire comme "en pause" plutôt que "en
cours" pendant la projection en direct — le bouton START/PAUSE restait
bloqué sur "REPRENDRE" après un tap. Détecté par le premier flow widget
Basketball (pas par les tests unitaires purs, qui ne testaient pas
explicitement `projectLiveElapsed` en état "running") ; un test unitaire
dédié a été ajouté pour ce cas précis avant de continuer.

## Phase Sports 2B — Basketball shot clock/timeouts/fautes, Futsal timeouts/fautes cumulées (statut : fait)

Complète Basketball et Futsal en de vrais tableaux de contrôle sportifs
(pas seulement score + chrono) — voir `docs/SPORT_RULES.md` pour les
sources officielles (FIBA Articles 18/29/41, FIFA Futsal Law 7/12/13) et
`docs/DATA_MODEL.md` "ShotClockRule/TimeoutRule/TeamFoulRule" pour
l'architecture. Football volontairement non modifié (aucun bug réel
détecté).

- [x] `ClockAccumulator` réutilisé pour `ShotClockEngine` (Basketball
      uniquement) — pas de duplication de logique de clock une 3e fois ;
      `SHOT_CLOCK_STARTED` sert à la fois de premier départ et de reprise
      après pause (pas de `SHOT_CLOCK_RESUMED` séparé).
- [x] `TimeoutEngine` — **une seule abstraction générique** pour
      Basketball (groupement par demi-terrain, sous-plafond des 2
      dernières minutes du Q4) et Futsal (groupement par période
      individuelle), aucune branche par sport dans l'engine.
- [x] `TeamFoulEngine` — **une seule abstraction générique** pour le bonus
      Basketball (seuil 5) et le DFKSAF Futsal (seuil 6) ; comportement de
      remise à zéro par période réglementaire / report en prolongation
      vérifié officiellement identique pour les deux sports, donc câblé
      dans l'engine plutôt que configurable.
- [x] Synchronisation game clock / shot clock : mettre en pause le game
      clock met en pause un shot clock actif dans la même transaction ;
      reprendre le game clock ne relance **jamais** automatiquement le
      shot clock (éviterait d'inventer une décision d'arbitre/possession).
- [x] `MatchRule.shotClockRule`/`timeoutRule`/`teamFoulRule` : trois champs
      optionnels additifs (pas de bump de `schemaVersion`), `null` pour
      Football (aucun des trois).
- [x] UI secondaire compacte (bande shot clock + tuiles fautes/temps
      morts) sous les contrôles primaires (score/chrono/undo/start-pause),
      conditionnelle par sport — Football ne montre rien de plus qu'avant.
      Indicateur bonus jamais uniquement par couleur (texte explicite
      "BONUS").
- [x] Undo universel étendu : `SHOT_CLOCK_RESET`, `TIMEOUT_TAKEN`,
      `TEAM_FOUL_ADDED` rejoignent `resolveMatchUndoTarget`'s ensemble
      d'events annulables, même mécanisme que score/période/tirs au but.
- [x] Tests : 3 nouveaux engines purs (33 tests), assertions ruleset
      étendues, 2 suites de flow widget dédiées (Basketball : shot clock
      reset 24/14/pause/expiration/synchro game-clock, fautes avec seuil
      bonus + undo, temps morts avec sous-plafond + undo, recovery
      complète après restart ; Futsal : absence de shot clock, quota par
      période avec reset à la période 2, seuil DFKSAF à 6 avec remise à
      zéro période 2 puis report en prolongation). 297 tests verts, 2 skip
      inchangés (SEQUENTIAL_SCORE, sans lien).
- [ ] Fautes de joueur individuelles / feuille de match complète : hors
      périmètre (voir `docs/SPORT_RULES.md`) — architecture `TeamFoulState`
      laissée ouverte pour ne pas bloquer un futur `PlayerFoulState`, mais
      rien construit dans cette phase.
- [ ] Build/tests natifs iOS/watchOS et QA runtime Android : mêmes
      réserves que la Phase Sports 2A (environnement non disponible ici).

## Phase 2 — Presets V1

> Jalon intermédiaire : `docs/RELEASE_0_1.md` couvre déjà un sous-ensemble
> (Score libre/Tennis/Padel/Pétanque, Chrono/Countdown/Lap, Sprint 30-30/
> Tabata/Gainage/Circuit simple) — atteignable avant la fin complète de
> cette phase.

- [ ] 9 presets Score (`docs/SPORT_RULES.md`).
- [ ] Presets Timer (chrono, countdown, lap, sprint).
- [ ] Presets Training (Tabata, HIIT, EMOM, AMRAP, Circuit, Gainage,
      Boxing, Musculation).
- [ ] Mode Custom (compteur/timer/workout/circuit personnalisés).

## Phase 3 — Watch (Apple + Wear OS)

- [ ] UI watch conforme `playtap-watch-ux` pour chaque catégorie.
- [ ] Synchronisation phone/watch (`playtap-watch-sync`).
- [ ] Fonctionnement watch autonome (sans phone à proximité).

## Phase 4 — Durcissement & release

- [ ] Passage complet `docs/RELEASE_CHECKLIST.md` / `playtap-release-gate`.
- [ ] Tests de charge sur l'historique (grand volume de sessions).
- [ ] Accessibilité complète.

## Post-MVP (non planifié, à réévaluer)

- Synchronisation cloud optionnelle.
- Fonctionnalités sociales.
- Monétisation.

Voir `docs/PRODUCT_SPEC.md` pour le détail du hors-scope V1 et les
raisons de ces exclusions.
