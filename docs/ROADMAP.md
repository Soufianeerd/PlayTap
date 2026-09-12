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

## Phase 1B.2 — Moteurs génériques restants

- [ ] Timer Engine (monotonic en exécution, timestamps pour la
      persistence — voir `playtap-timer-engine`), validé contre
      `/contracts/timer`.
- [ ] Interval Engine (`playtap-interval-engine`), validé contre
      `/contracts/interval`.
- [ ] Workout Sequence Engine (`playtap-workout-engine`).
- [ ] Runners de conformité Swift/Kotlin (le runner Dart existe depuis
      la Phase 1B.1 — `mobile/test/conformance/`) exécutant les mêmes
      fixtures `/contracts` (voir `docs/CONFORMANCE.md`).
- [ ] Reste du Score Engine générique : TARGET_SCORE, SEQUENTIAL_SCORE,
      TEAM_SCORE, SETS, BEST_OF, WIN_BY (voir points d'extension déjà
      identifiés dans `playtap-sports-rules`).

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
