---
name: playtap-timer-engine
description: Moteur de temps fiable PlayTap (chronomètre, countdown, laps, pause/resume, persistence). Utiliser pour toute implémentation impliquant du temps qui s'écoule (chrono, countdown, sprint timer, lap timer).
---

# PlayTap — Timer Engine

## Ce que couvre ce moteur

- Chronomètre (stopwatch, compte vers le haut)
- Countdown (compte vers le bas)
- Laps (tours intermédiaires horodatés)
- Pause / resume
- Comportement background (app en arrière-plan, écran verrouillé, montre
  endormie)
- Recovery après crash / kill / redémarrage
- Persistence de l'état en cours

## Règle absolue : source de vérité = timestamps, jamais un compteur décrémenté

**Ne jamais implémenter un timer fiable en faisant uniquement :**

```
// INTERDIT
remaining--  // à chaque tick d'un Timer.periodic(1 seconde)
```

Cette approche dérive dès que :
- l'écran se verrouille,
- l'application passe en arrière-plan,
- le thread/timer est throttle par l'OS,
- la montre s'endort ou réduit sa fréquence de rafraîchissement.

### Modèle correct

Un timer PlayTap est décrit par des faits immuables, pas par un compteur
mutable :

```
TimerSpec:
  schemaVersion: Int
  mode: STOPWATCH | COUNTDOWN
  durationTarget: Duration?      // requis si COUNTDOWN

TimerState (dérivé, jamais stocké tel quel comme vérité) :
  startedAt: Timestamp
  pausedIntervals: [(pausedAt: Timestamp, resumedAt: Timestamp?)]
  laps: [Timestamp]

elapsed(now) =
  (now - startedAt) - sum(pausedIntervals durations, en excluant
  l'intervalle de pause en cours s'il n'est pas encore résumé)

remaining(now) = durationTarget - elapsed(now)   // countdown seulement
```

L'UI ne fait que recalculer `elapsed(now)` / `remaining(now)` à chaque frame
ou tick d'affichage — elle ne fait jamais confiance à un compteur qui
s'auto-décrémente indépendamment du temps réel.

### Quelle horloge pour `now` ?

Deux sources de temps, pour deux besoins distincts :

- **Pendant que le process est vivant** (timer actif, app au premier
  plan ou en arrière-plan mais non tué) : calculer `now` à partir d'une
  horloge **monotonic/elapsed** de la plateforme (ex : `Duration` basée
  sur une horloge monotonic en Dart, `DispatchTime`/
  `ProcessInfo.systemUptime` en Swift, `SystemClock.elapsedRealtime()`
  en Kotlin/Android). Une horloge murale peut sauter en avant ou en
  arrière (changement de fuseau, heure d'été, correction NTP, réglage
  manuel) — un timer basé sur elle peut geler, sauter, ou finir en avance
  sans qu'aucun bug de logique ne soit en cause.
- **Pour la persistence et le recovery** (l'app est fermée, le process
  est tué, la montre s'éteint puis se réveille) : une horloge monotonic
  ne survit pas à un redémarrage de process — elle repart de zéro. Il
  faut donc persister `startedAt` et les bornes de `pausedIntervals` en
  **timestamps muraux** (voir `docs/DATA_MODEL.md` — "Modèle temporel"),
  et recalculer `elapsed`/`remaining` à partir de ces timestamps muraux
  au moment du recovery, pas à partir d'une horloge monotonic qui n'a
  plus de sens après un redémarrage.

En résumé : monotonic pour la fiabilité pendant l'exécution continue,
timestamps muraux pour survivre à une interruption complète du process.

### Pause / resume

Une pause ajoute un nouvel intervalle `(pausedAt: now, resumedAt: null)`. Un
resume complète cet intervalle avec `resumedAt: now`. Le temps écoulé
pendant la pause est exclu du calcul — jamais compensé par un ajustement
manuel du compteur.

### Laps

Un lap est un timestamp, pas une soustraction manuelle. Le temps du lap N
= `laps[N] - laps[N-1]` (ou `startedAt` pour le premier lap), recalculé à
la demande.

### Background & réveil montre

À chaque retour au premier plan (ou réveil de la montre), l'UI doit
recalculer l'état à partir de `startedAt` + `pausedIntervals` actuels — ne
jamais reprendre un compteur en mémoire qui aurait pu être suspendu par
l'OS. Persister `startedAt` et `pausedIntervals` dès leur création (voir
`playtap-offline-first`), pas seulement à la fermeture de l'app.

### Recovery

Après un kill de process ou redémarrage device : relire `TimerSpec` +
`TimerState` persistés, recalculer `elapsed(now)` immédiatement. Si le
countdown est déjà à 0 ou négatif au moment du recovery, traiter comme
terminé (déclencher la fin de timer) plutôt que d'afficher un état
incohérent.

### Fin de countdown

La fin est détectée par comparaison (`remaining(now) <= 0`), jamais par un
compteur qui atteindrait exactement zéro — un tick manqué ne doit jamais
empêcher la détection de fin.

### Conformité inter-plateformes

Les fixtures `/contracts/timer` (voir `docs/CONFORMANCE.md`) définissent
des points de contrôle (`expectedCheckpoints`, à des `atMs` donnés) que
Dart, Swift et Kotlin doivent résoudre à l'identique — y compris à
travers une pause/resume.
