---
name: playtap-workout-engine
description: Moteur de séquences d'entraînement PlayTap (Exercise, Rest, Timed block, Manual completion, Repeat group). Utiliser pour HIIT, Circuit Training, EMOM, AMRAP, musculation, boxe, ou toute séance multi-étapes.
---

# PlayTap — Workout Sequence Engine

## Rôle

Modéliser une séance composée de plusieurs étapes hétérogènes, au-dessus
du `playtap-interval-engine` (pour les portions chronométrées répétitives)
et du `playtap-timer-engine` (pour le temps brut). Ce moteur ajoute la
notion d'**étapes non-uniformes** et de **complétion manuelle**, que
l'Interval Engine seul ne couvre pas.

## Modèle conceptuel

```
WorkoutStep (union) :
  ExerciseStep      — un exercice nommé, avec durée OU répétitions cibles
  RestStep          — pause chronométrée entre exercices
  TimedBlockStep    — bloc chronométré générique (ex: 1 minute de gainage)
  ManualStep        — étape sans durée, l'utilisateur marque "terminé"
                       lui-même (ex: "10 pompes", "1 série de squats")

RepeatGroup:
  steps: [WorkoutStep]
  repeat: Int             // répète tout le sous-groupe N fois

WorkoutSequence:
  schemaVersion: Int      // voir DATA_MODEL.md
  steps: [WorkoutStep | RepeatGroup]   // liste ordonnée, imbrication
                                        // de RepeatGroup possible
```

## Cas d'usage → mapping moteur

| Cas | Composition |
|---|---|
| HIIT | `IntervalProgram` (voir `playtap-interval-engine`) encapsulé comme séquence de `TimedBlockStep` répétés |
| Circuit Training | `RepeatGroup` de plusieurs `ExerciseStep` (souvent `ManualStep` ou durée fixe) + `RestStep` entre tours |
| Gainage | `TimedBlockStep` unique ou séquence de `TimedBlockStep` |
| EMOM ("every minute on the minute") | `RepeatGroup` de `TimedBlockStep` de 60s, l'exercice doit être fini avant la fin de la minute (temps restant = temps de repos) |
| AMRAP ("as many rounds as possible") | Un seul `TimedBlockStep` global (durée totale) contenant un `RepeatGroup` sans limite de répétitions fixe — le compteur de tours est incrémenté manuellement par l'utilisateur |
| Musculation / temps de repos | Alternance `ManualStep` (série) + `RestStep` chronométré |
| Boxe | `IntervalProgram` (rounds/repos) — voir `playtap-interval-engine` |
| Running intervals | `IntervalProgram` |

## Règles de conception

- Ne jamais créer de type de step spécifique à un sport ou une méthode
  d'entraînement nommée. Toute nouvelle méthode (ex: une variante EMOM)
  doit se construire avec les 4 types de `WorkoutStep` existants.
- `RepeatGroup` doit pouvoir s'imbriquer (un `RepeatGroup` peut contenir un
  autre `RepeatGroup`) pour couvrir des séances complexes (ex: 3 circuits
  de 4 exercices x2 tours chacun).
- Un `ManualStep` n'a pas de durée intrinsèque mais doit tout de même
  enregistrer un timestamp de début/fin réel dans l'historique — pour la
  cohérence avec `playtap-offline-first` et l'event sourcing du
  `playtap-score-engine`/Session Engine.
- La progression dans la séquence (étape courante, étapes restantes) est
  un état dérivé de la position dans `WorkoutSequence` + des events de
  complétion, pas un simple index muté à la main sans trace.

## Conformité inter-plateformes

`/contracts/workout` est réservé pour les fixtures de `WorkoutSequence`
(voir `docs/CONFORMANCE.md`) — aucune fixture n'y est encore définie ; à
peupler dès que le Workout Engine passe en implémentation (Phase 1/2).

## AMRAP — attention particulière

AMRAP combine une durée totale fixe (Timer Engine, countdown) avec un
comptage libre de tours (Score Engine, `FREE_SCORE`). Ne pas essayer de
tout faire dans le Workout Engine seul : le "combien de tours" doit
passer par le Score Engine pour bénéficier de l'undo et de l'historique
d'events.
