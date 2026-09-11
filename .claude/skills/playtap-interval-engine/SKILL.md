---
name: playtap-interval-engine
description: Moteur d'intervalles PlayTap (work/rest/warmup/cooldown/repeat, transitions, haptics, sound). Utiliser pour Tabata, sprint intervals, boxing rounds, ou tout enchaînement cyclique de phases chronométrées.
---

# PlayTap — Interval Engine

## Rôle

Enchaîner des phases chronométrées répétées, en s'appuyant sur le
`playtap-timer-engine` pour chaque phase individuelle (jamais de
décompte maison — mêmes règles de dérive à éviter).

## Modèle conceptuel

```
IntervalPhase:
  type: WARMUP | WORK | REST | COOLDOWN
  duration: Duration
  label: String?              // ex: "Sprint", "Recovery", "Round 1"

IntervalBlock:
  phases: [IntervalPhase]     // séquence d'une "unité" répétable
  repeat: Int                 // nombre de répétitions du bloc

IntervalProgram:
  schemaVersion: Int           // voir DATA_MODEL.md
  warmup: IntervalPhase?
  blocks: [IntervalBlock]
  cooldown: IntervalPhase?
```

## Presets typiques (à exprimer comme `IntervalProgram`, pas comme code dédié)

- **Tabata 20/10 x8** : 1 block = [WORK 20s, REST 10s], repeat 8
- **Sprint 30/30 x10** : 1 block = [WORK 30s, REST 30s], repeat 10
- **Boxing 3min/1min** : 1 block = [WORK 180s, REST 60s], repeat N rounds
- **1min/1min** : générique, mêmes principes

Tout nouveau preset d'intervalles doit se construire en assemblant des
`IntervalPhase`/`IntervalBlock` existants — jamais un nouveau moteur par
sport ou par type d'entraînement.

## Transitions

Chaque changement de phase (`WORK → REST`, `REST → WORK`, dernier
`repeat` → phase suivante ou fin) doit déclencher, de façon synchrone :

1. Un signal haptique distinct par type de transition (ex: pattern différent
   pour "début work" vs "début rest" vs "fin de programme").
2. Un signal sonore optionnel (configurable, off par défaut si l'app est en
   silencieux — respecter les réglages système).
3. Une mise à jour visuelle immédiate (pas d'animation lente — voir
   `playtap-watch-ux`).

### Countdown avant phase ("3-2-1")

Un compte à rebours court (ex: 3 secondes) avant le début d'une nouvelle
phase est un pattern courant et recommandé pour laisser le temps de
réagir physiquement. Le modéliser comme une `IntervalPhase` de type
transition à part entière (durée fixe courte), pas comme un cas spécial
hardcodé dans l'UI.

## Fiabilité temporelle

L'`IntervalProgram` est piloté par une timeline absolue dérivée de
`startedAt` (voir `playtap-timer-engine`), pas par l'enchaînement de
timers indépendants qui pourraient dériver phase après phase. La phase
courante et le temps restant dans la phase se calculent à tout instant par
`now - startedAt`, jamais par accumulation de décomptes successifs.

## Pause globale

Une pause sur un `IntervalProgram` doit geler la timeline entière (même
mécanisme de `pausedIntervals` que le Timer Engine), pas seulement la
phase en cours — sinon les phases suivantes se décalent au resume.

## Conformité inter-plateformes

Tout `IntervalProgram` de référence (Tabata, sprint, boxing...) doit être
exprimé comme fixture dans `/contracts/interval` (voir
`docs/CONFORMANCE.md`) pour garantir que Dart, Swift et Kotlin résolvent
la même phase/le même temps restant aux mêmes instants.
