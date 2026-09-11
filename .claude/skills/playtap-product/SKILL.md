---
name: playtap-product
description: Vision produit PlayTap, principes MVP, définition de done, et garde-fous anti feature-creep. Utiliser pour toute décision de scope, priorisation ou arbitrage produit.
---

# PlayTap — Product

## Vision

"If I need to count or time something during sport, PlayTap can probably do
it."

Application mobile + smartwatch universelle pour compter et chronométrer
pendant le sport. Pas une app de fitness tracking, pas un réseau social,
pas un coach IA. Un outil rapide et fiable.

## Catégories (V1)

| Catégorie | Contenu |
|---|---|
| Scores | Tennis, Padel, Tennis de table, Badminton, Pétanque, Basketball, Football/Futsal, Volleyball, Score libre |
| Timers | Chronomètre, Countdown, Lap timer, Sprint timer |
| Training | Fractionné, HIIT, Tabata, Circuit Training, Gainage, EMOM, AMRAP, Boxing Timer, Musculation |
| Custom | Compteur personnalisé, Timer personnalisé, Workout personnalisé, Circuit personnalisé |

Toute nouvelle catégorie doit se ranger dans l'une de ces 4 familles ou
justifier explicitement pourquoi elle crée une 5e famille.

## Priorité : simplicité

- Une activité doit pouvoir démarrer en moins de 3 taps depuis l'accueil.
- Pas de configuration obligatoire non essentielle avant de commencer.
- Les valeurs par défaut doivent être jouables immédiatement (ex: Tabata =
  20/10 x8 par défaut).

## Séparation phone / watch

- **Phone** = configuration, personnalisation, historique. C'est l'endroit
  où l'utilisateur réfléchit.
- **Watch** = exécution pendant l'effort. C'est l'endroit où l'utilisateur
  agit sans réfléchir.

Ne jamais concevoir une feature qui exige une interaction complexe sur la
montre pendant l'effort. Voir `playtap-watch-ux`.

## Anti feature-creep

Avant d'ajouter une feature, vérifier :

1. Sert-elle à compter ou chronométrer pendant le sport ? Sinon, refuser
   ou reporter hors MVP.
2. Peut-elle être un preset d'un moteur existant plutôt qu'un nouveau
   système ? Toujours préférer le preset.
3. Introduit-elle une dépendance réseau/cloud/compte obligatoire ? Interdit
   pour le MVP — voir `playtap-offline-first`.
4. Complexifie-t-elle l'écran montre pendant l'activité ? Si oui, la
   déplacer côté phone ou la refuser.

Ne pas concevoir pour des besoins hypothétiques futurs (ligues, coaching
social, classements en ligne, paiement...) tant que le MVP n'est pas
solide.

## Définition de "Done" pour une feature PlayTap

Une feature n'est terminée que si, dans cet ordre :

1. Le code compile sans erreur (mobile ET watch/wear si concerné).
2. `flutter analyze` / équivalent natif ne remonte pas de nouvelle erreur.
3. Les tests unitaires du moteur concerné passent.
4. Le parcours a été testé réellement (simulateur/device via Mobile MCP ou
   XcodeBuildMCP), pas seulement lu dans le code.
5. Le comportement offline a été vérifié (mode avion).
6. La reprise de session après fermeture app / réveil montre fonctionne.

Voir aussi `playtap-release-gate` pour la checklist avant release globale.

## Principes UX principaux

- Gros éléments tactiles, contraste élevé, peu de texte.
- Feedback immédiat (haptique + visuel), jamais de confirmation superflue.
- Undo systématique sur les actions de score/pointage.
- Aucune perte de données : toute session interrompue doit pouvoir
  reprendre.
