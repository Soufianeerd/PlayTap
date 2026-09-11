---
name: playtap-watch-ux
description: Règles UX obligatoires pour l'interface montre (Apple Watch et Wear OS) pendant une activité sportive. Utiliser pour toute écran, composant, ou interaction conçue pour être utilisée sur la montre pendant l'effort.
---

# PlayTap — Watch UX

## Contexte : utilisation en mouvement, sous effort

L'utilisateur interagit avec la montre en respirant fort, en sueur, sans
regarder longtemps l'écran, parfois avec des gants ou les mains mouillées.
Chaque règle ci-dessous découle de cette contrainte.

## Règles obligatoires

- **Grosses zones tactiles.** Cibles tactiles larges (viser le maximum
  autorisé par la plateforme), jamais de petits boutons ou icônes serrées.
- **Informations critiques énormes.** Le score courant, le temps restant,
  la phase en cours doivent être lisibles en un coup d'œil, en grand
  format, au centre de l'écran.
- **Peu de texte.** Privilégier chiffres, symboles, couleurs plutôt que
  des phrases. Aucun paragraphe explicatif à l'écran pendant l'activité.
- **Contrastes élevés.** Fond/texte à fort contraste, lisible en plein
  soleil.
- **Interaction possible en mouvement.** Pas de gestes fins (pincer,
  glisser précisément) requis pour les actions courantes — tap simple ou
  Digital Crown/bouton physique suffisant.
- **Haptics importants.** Chaque action et chaque transition (fin de
  phase, point marqué, fin de programme) doit avoir un retour haptique
  distinct et immédiat, sans dépendre uniquement du visuel.
- **Feedback immédiat.** Aucune latence perceptible entre le tap et la
  mise à jour affichée/haptique.
- **Pas de popup inutile.** Aucune boîte de dialogue qui interrompt le
  flux pendant l'activité.
- **Pas de confirmation après chaque point.** Marquer un point/action doit
  être instantané et sans étape de confirmation. L'undo (voir
  `playtap-score-engine`) est le filet de sécurité, pas une confirmation
  a priori.
- **Pas d'animations lentes.** Transitions courtes (voir directives
  motion de la plateforme), jamais d'animation qui retarde la lisibilité
  de l'information critique.
- **Pas de menus compliqués pendant l'effort.** Aucune navigation
  multi-niveaux pendant une session active. Si un réglage est nécessaire,
  il se fait avant le démarrage (côté phone si possible — voir
  `playtap-product`).

## Objectif mesurable

La montre doit être exploitable rapidement sans regarder longtemps l'écran
— viser une compréhension de l'état courant (score/temps/phase) en moins
d'une seconde de regard, et une action (marquer un point, pause, passer à
la phase suivante) en un seul tap ou une seule pression physique.

## Ce qui appartient au phone, pas à la montre

- Choix du sport / mode d'entraînement.
- Configuration des règles (nombre de sets, durée des phases, etc.).
- Historique détaillé et statistiques.
- Personnalisation (noms des joueurs, thèmes, etc.).

Si une fonctionnalité tente d'apporter l'un de ces éléments sur
l'écran montre pendant l'activité, la reconsidérer : soit elle est
déplacée côté phone (avant le démarrage), soit elle est simplifiée à
l'extrême pour tenir dans les règles ci-dessus.
