# PlayTap — Release 0.1 (first vertical slice)

> Le MVP complet reste défini par `docs/MVP.md`. Release 0.1 est un
> **milestone plus étroit** : le premier vertical slice publiable,
> complet de bout en bout (phone + watch) sur un sous-ensemble du scope.
> Rien du MVP global n'est supprimé — seulement séquencé.

## Contenu

### Score
- Score libre
- Tennis
- Padel
- Pétanque

### Timer
- Chronomètre
- Countdown
- Lap Timer

### Training
- Sprint 30/30
- Tabata
- Gainage
- Circuit personnalisé simple

### Phone
- Home
- Activity library (liste des activités disponibles par catégorie)
- Configuration (avant démarrage)
- Active session (vue de suivi pendant l'activité, si le phone reste
  présent)
- History
- Favorites

### Watch
- Resume active session (recovery — voir `playtap-offline-first`,
  `playtap-timer-engine`)
- Favorites
- Score interaction (marquer un point, undo)
- Timer/interval execution
- Pause/resume
- Undo
- Haptic feedback
- Local recovery (fonctionnement autonome — voir `playtap-watch-sync`)

## Contraintes (héritées du MVP, non négociables pour 0.1)

- Offline-first : aucun flow ci-dessus ne dépend d'Internet.
- Sans compte, sans authentification.
- Sans backend obligatoire.
- Sans paiement.

## Pourquoi ce sous-ensemble

- Score : Tennis/Padel exercent `SEQUENTIAL_SCORE` + `SETS` + `BEST_OF` +
  `WIN_BY` (le cas le plus riche du Score Engine) ; Pétanque exerce
  `TARGET_SCORE` + `TEAM_SCORE` sans sets ; Score libre exerce
  `FREE_SCORE`. Ensemble, ces 4 presets couvrent la quasi-totalité des
  modes `ScoreRule` définis dans `playtap-score-engine`, sans attendre
  Basketball/Football/Volleyball/Badminton/Tennis de table pour valider
  le moteur.
- Timer : les 3 modes fondamentaux (chrono, countdown, laps) sans encore
  le sprint timer dédié (déjà couvert conceptuellement par countdown).
- Training : Sprint 30/30 et Tabata exercent l'Interval Engine (deux
  configurations différentes de durée/répétitions) ; Gainage exerce le
  Timer/Workout Engine en `TimedBlockStep` simple ; Circuit personnalisé
  simple exerce le Workout Engine avec `RepeatGroup` — ensemble, ces 4 cas
  couvrent les briques structurelles des deux moteurs sans attendre HIIT/
  EMOM/AMRAP/Boxing/Musculation.
- Watch : toutes les capacités listées sont transverses (pas spécifiques
  à un sport) — les valider une fois avec ce sous-ensemble les valide
  pour l'ensemble du MVP.

## Sortie de Release 0.1

Passage complet de `docs/RELEASE_CHECKLIST.md` (skill
`playtap-release-gate`) sur exactement ce sous-ensemble de flows — pas
besoin d'attendre les presets restants du MVP complet.
