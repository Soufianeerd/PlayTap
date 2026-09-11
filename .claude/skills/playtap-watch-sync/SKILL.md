---
name: playtap-watch-sync
description: Synchronisation phone/watch PlayTap (session ownership, UUID, event sync, idempotency, deduplication, conflict strategy, reconnection, offline watch operation). Utiliser pour toute feature impliquant une communication phone ↔ montre.
---

# PlayTap — Watch Sync

## Principe fondateur

**Une montre doit pouvoir continuer une session si le téléphone
disparaît.** La montre n'est jamais un simple écran distant dépendant du
téléphone — elle a sa propre capacité de fonctionnement offline complet
(voir `playtap-offline-first`). La synchronisation est une optimisation de
confort (voir l'historique consolidé, configurer depuis le phone), jamais
une dépendance de fonctionnement.

## Session ownership

Chaque session a un propriétaire désigné au démarrage (le device qui l'a
créée). L'autre device peut s'y connecter en lecture/écriture synchronisée
tant que la connexion existe, mais n'est jamais bloqué si la connexion
tombe — il continue avec son propre état local.

## Identité et idempotency

- Chaque session a un **UUID** unique généré à la création, jamais réutilisé.
- Chaque event (voir `playtap-score-engine`, `playtap-interval-engine`,
  `playtap-workout-engine`) a également un identifiant **UUID** unique.
- Toute réception d'un event déjà connu (même id) doit être un no-op
  (**idempotent**) — un renvoi dû à une reconnexion ne doit jamais dupliquer
  l'effet de l'event.

## Event ordering — timestamp seul insuffisant

Les horloges du phone et de la watch peuvent diverger (dérive, correction
NTP asynchrone, etc.). **Le `timestamp` seul ne doit jamais déterminer
l'ordre logique des events entre appareils.**

Chaque event porte donc, en plus de son `id` (UUID) et de son `timestamp`
(horloge murale, conservé mais informatif) :

```
originDevice: PHONE | WATCH_APPLE | WATCH_WEAROS
originSequence: Int    // compteur local de l'appareil émetteur, incrémenté
                        // de 1 pour chaque event qu'IL produit dans cette
                        // session — jamais partagé/réinitialisé par
                        // l'autre appareil
```

### Règle de tri/réconciliation (déterministe)

1. **L'ordre intra-device est sacré.** Les events d'un même
   `originDevice` sont toujours ordonnés par `originSequence` croissant,
   quoi qu'indique le `timestamp`. Si une anomalie d'horloge fait
   apparaître un `timestamp` non croissant pour un même device, c'est
   `originSequence` qui fait foi pour cet appareil, jamais le
   `timestamp`.
2. **L'entrelacement inter-device utilise `timestamp` comme signal
   best-effort.** Les deux horloges restent globalement proches (même
   personne, deux OS modernes synchronisés NTP) — `timestamp` reste donc
   un bon indicateur approximatif de l'ordre réel entre events de deux
   devices différents, mais jamais une garantie absolue.
3. **Tie-break totalement déterministe** en cas d'égalité ou
   d'ambiguïté de `timestamp` entre devices : trier par
   `(timestamp, originDevice, originSequence, id)` — cette clé produit
   un ordre total unique et reproductible sur n'importe quel appareil qui
   fait le merge, tout en respectant la règle 1 (jamais d'inversion
   intra-device).

Ce n'est pas une architecture distribuée avec horloges vectorielles ou
consensus — PlayTap reste un produit phone ↔ watch pour un seul
utilisateur. Le but est uniquement : (a) ne jamais réordonner les events
d'un même appareil entre eux, (b) obtenir un ordre total identique sur
les deux appareils après merge, sans mécanisme plus complexe que
nécessaire.

## Déduplication

Le mécanisme de sync doit détecter et ignorer les events déjà appliqués
localement avant de les rejouer. S'appuyer sur l'id unique de l'event, pas
sur une comparaison d'état (fragile face aux races).

## Stratégie de conflit

Si les deux devices ont produit des events divergents pendant une
déconnexion (cas rare mais possible : ex. undo sur un device pendant que
l'autre ajoutait un point) :

1. Fusionner par **union des event logs**, triés selon la règle
   "Event ordering" ci-dessus.
2. Re-dériver l'état final par replay complet (le Score/Timer/Interval/
   Workout Engine sont déjà conçus pour ça — voir leurs skills respectifs).
3. Ne jamais faire un merge silencieux qui perdrait un event d'un des deux
   devices — en cas de doute, conserver les deux et laisser le replay
   trancher via l'ordre déterministe.

## Reconnexion

À la reconnexion (WatchConnectivity côté Apple, Data Layer API côté Wear
OS) :

1. Chaque device envoie l'id du dernier event connu.
2. Chaque device transmet à l'autre uniquement les events manquants
   (delta), pas l'historique complet à chaque fois — sauf lors d'une
   toute première connexion.
3. Après réception, chaque device réconcilie via la stratégie de conflit
   ci-dessus si nécessaire.

## Fonctionnement montre 100% offline

Si la montre n'a jamais été connectée au téléphone pendant une session (ou
perd la connexion dès le début), elle doit pouvoir :

- créer sa propre session avec son propre UUID,
- fonctionner comme source de vérité autonome jusqu'à une éventuelle
  synchronisation ultérieure,
- transmettre l'historique complet au téléphone dès qu'une connexion
  redevient disponible (même après la fin de l'activité).

## Plateformes

- **Apple Watch** : `WatchConnectivity` — privilégier `transferUserInfo`/
  application context pour la fiabilité offline-tolerant plutôt qu'une
  dépendance à une session live constante. Consulter Context7 pour l'API
  courante avant implémentation (voir règle Context7 dans `CLAUDE.md`).
- **Wear OS** : Data Layer API (`MessageClient`, `DataClient`) — même
  principe de tolérance à la déconnexion. Consulter Context7 avant
  implémentation.
