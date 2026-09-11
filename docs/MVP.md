# PlayTap — MVP

> Premier jalon plus étroit avant d'atteindre ce MVP complet : voir
> `docs/RELEASE_0_1.md`.

## Définition du MVP

Le MVP PlayTap est atteint quand un utilisateur peut, **entièrement hors
ligne**, sur phone et watch :

1. Choisir et configurer une activité dans chacune des 4 catégories
   (Score, Timer, Training, Custom) depuis le phone.
2. Démarrer, exécuter et terminer cette activité principalement depuis la
   watch, avec une UX conforme à `playtap-watch-ux`.
3. Retrouver l'activité dans l'historique local du phone.
4. Fermer l'app ou éteindre l'écran en cours d'activité et reprendre
   sans perte de données (`playtap-offline-first`, `playtap-timer-engine`
   — recovery).
5. Utiliser la watch seule (téléphone hors de portée) sans perte de
   fonctionnalité critique, puis resynchroniser au retour de connexion
   (`playtap-watch-sync`).

## Sports/presets V1 requis pour le MVP

Voir `docs/SPORT_RULES.md` — les 9 presets Score (Tennis, Padel, Tennis de
table, Badminton, Pétanque, Basketball, Football/Futsal, Volleyball,
Score libre) doivent tous être fonctionnels avant de considérer le MVP
complet côté Score.

Training : au minimum un représentant de chaque méthode listée dans
`CLAUDE.md` (Tabata, HIIT générique, EMOM, AMRAP, Circuit, Gainage,
Boxing Timer, Musculation) doit être testé de bout en bout.

## Hors MVP

Voir `docs/PRODUCT_SPEC.md` section "Hors scope V1" et `docs/ROADMAP.md`.

## Critère de sortie

Le MVP n'est déclaré prêt qu'après passage complet de
`docs/RELEASE_CHECKLIST.md` (skill `playtap-release-gate`).
