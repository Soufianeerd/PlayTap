# PlayTap — Product Spec

> Vision, principes MVP et définition de done : voir `CLAUDE.md` et le
> skill `playtap-product`. Ce document détaille le scope fonctionnel V1.

## Scope V1 par catégorie

### Scores (voir `docs/SPORT_RULES.md`)
Tennis, Padel, Tennis de table, Badminton, Pétanque, Basketball,
Football/Futsal, Volleyball, Score libre.

### Timers
- Chronomètre — temps qui s'écoule, laps optionnels.
- Countdown — décompte vers zéro, alerte à la fin.
- Lap timer — chronomètre avec tours horodatés.
- Sprint timer — countdown court répétable (souvent un preset Interval
  Engine à un seul cycle).

### Training
Fractionné, HIIT, Tabata, Circuit Training, Gainage, EMOM, AMRAP, Boxing
Timer, Musculation/temps de repos. Voir `playtap-interval-engine` et
`playtap-workout-engine` pour le mapping technique de chaque méthode.

### Custom
Compteur personnalisé (preset Score Engine `FREE_SCORE` configurable),
Timer personnalisé, Workout personnalisé, Circuit personnalisé — tous
construits en composant les moteurs génériques, jamais en code dédié.

## Hors scope V1 (explicitement)

- Comptes utilisateurs, authentification.
- Backend/cloud obligatoire, synchronisation multi-appareils au-delà de
  phone ↔ watch de l'utilisateur.
- Fonctionnalités sociales (partage de scores en ligne, classements,
  amis).
- Coaching IA, recommandations automatiques.
- Paiement / abonnement (à réévaluer post-MVP, voir `docs/ROADMAP.md`).

## Parcours utilisateur clé (P0)

1. Ouvrir l'app → choisir une catégorie → choisir/configurer une activité
   (phone).
2. Démarrer l'activité (phone ou watch).
3. Exécuter l'activité principalement depuis la watch : scorer,
   chronométrer, passer les phases, pause/reprise.
4. Terminer l'activité.
5. Consulter le résultat dans l'historique (phone).

Ce parcours doit fonctionner intégralement hors ligne — voir
`docs/MVP.md` et `playtap-offline-first`.
