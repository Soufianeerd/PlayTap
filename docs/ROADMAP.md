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
- [ ] Choix définitif de la stack de persistance mobile (SQLite/Drift ou
      alternative justifiée — voir `docs/DATA_MODEL.md`).
- [ ] Scaffolding initial `/mobile`, `/apple-watch`, `/wear-os`.

## Phase 1 — Moteurs génériques

- [ ] Score Engine + tests déterministes (`playtap-score-engine`),
      validés contre les fixtures `/contracts/score`.
- [ ] Timer Engine (monotonic en exécution, timestamps pour la
      persistence — voir `playtap-timer-engine`), validé contre
      `/contracts/timer`.
- [ ] Interval Engine (`playtap-interval-engine`), validé contre
      `/contracts/interval`.
- [ ] Workout Sequence Engine (`playtap-workout-engine`).
- [ ] Runners de conformité Dart/Swift/Kotlin exécutant les mêmes
      fixtures `/contracts` (voir `docs/CONFORMANCE.md`).
- [ ] Persistance locale offline-first (`playtap-offline-first`).

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
