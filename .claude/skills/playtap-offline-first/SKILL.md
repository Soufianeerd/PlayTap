---
name: playtap-offline-first
description: Règles de persistance locale PlayTap (sessions, events, presets, favoris, historique, crash recovery, migrations de schéma). Utiliser pour toute décision de stockage local ou de comportement offline.
---

# PlayTap — Offline First

## Principe non négociable

Le MVP PlayTap fonctionne intégralement sans Internet. Aucune feature
essentielle (score, timer, séance, historique local, reprise de session)
ne doit dépendre d'un appel réseau pour être utilisable ou pour se
terminer. Pas de backend, pas de compte, pas d'authentification, pas de
cloud obligatoire.

## Ce qui doit être persisté localement

| Donnée | Pourquoi |
|---|---|
| Sessions (en cours et terminées) | Reprise après crash/fermeture, historique |
| Events (ScoreEvent, transitions d'intervalle, complétions de step) | Event sourcing — voir `playtap-score-engine`, `playtap-interval-engine`, `playtap-workout-engine` |
| Presets (sports, programmes d'intervalles, séances custom) | Réutilisation sans reconfiguration, disponibilité offline |
| Favoris | Accès rapide depuis l'accueil |
| Historique | Consultation phone, voir `playtap-product` |

Détail du schéma : voir `docs/DATA_MODEL.md`.

## Écriture immédiate, pas de buffer en mémoire uniquement

Tout event qui change l'état d'une session active (`ScoreEvent`, début/fin
de phase, complétion de step) doit être écrit en stockage local dès sa
création — pas seulement tenu en mémoire et flushé à la fermeture de l'app.
Un kill de process par l'OS ne doit jamais perdre de données de session en
cours.

## Crash recovery

Au lancement de l'app (phone ou watch), si une session active existe en
stockage sans avoir été marquée comme terminée :

1. La proposer en reprise immédiate (pas de perte silencieuse, mais pas
   non plus de flot de questions bloquant l'utilisateur).
2. Recalculer l'état courant par replay des events persistés (voir
   `playtap-score-engine`, `playtap-timer-engine`) — jamais faire confiance
   à un état "snapshot" qui pourrait être désynchronisé.

## Migration de schéma

Toute évolution du schéma de stockage local doit :

- être versionnée explicitement,
- fournir un chemin de migration des données existantes (pas de perte de
  l'historique utilisateur lors d'une mise à jour de l'app),
- être testée avec des données représentatives d'une version antérieure
  avant release (voir `playtap-release-gate`).

## Réseau : usage strictement optionnel

Si une fonctionnalité réseau existe (ex: sync future, export), elle doit :

- être un bonus explicitement optionnel, jamais un prérequis,
- dégrader proprement en mode avion sans bloquer ni ralentir le parcours
  principal,
- ne jamais être sur le chemin critique de démarrage, déroulement, ou fin
  d'une activité.
