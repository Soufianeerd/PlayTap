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
- [ ] Reste du Score Engine générique : TARGET_SCORE, SEQUENTIAL_SCORE,
      TEAM_SCORE, SETS, BEST_OF, WIN_BY (voir points d'extension déjà
      identifiés dans `playtap-sports-rules`) — hors périmètre.
- [ ] Apple Watch Timer, Wear OS Timer, synchronisation watch — hors
      périmètre (voir la politique Xcode/CI macOS différée dans
      `CLAUDE.md`/`docs/ARCHITECTURE.md`).

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
