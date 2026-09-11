# PlayTap — Watch Sync

> Le détail complet (session ownership, UUID, idempotency, déduplication,
> stratégie de conflit, reconnexion, fonctionnement offline de la montre)
> vit dans le skill **`playtap-watch-sync`** — source de vérité unique.

## Résumé rapide

- Principe fondateur : une montre continue une session même si le
  téléphone disparaît.
- Chaque session et chaque event a un id UUID unique ; la réception d'un
  event déjà connu est un no-op (idempotent).
- **Event ordering** : chaque event porte `originDevice` +
  `originSequence` (compteur local par appareil) en plus de `timestamp`.
  Le `timestamp` seul ne détermine jamais l'ordre entre appareils (les
  horloges peuvent diverger) — l'ordre intra-device suit toujours
  `originSequence`, l'entrelacement inter-device utilise `timestamp`
  comme signal best-effort, avec tie-break déterministe
  `(timestamp, originDevice, originSequence, id)`. Détail complet :
  section "Event ordering" du skill `playtap-watch-sync`.
- En cas de divergence après déconnexion : union des event logs, triés
  selon la règle ci-dessus, re-dérivation de l'état par replay — jamais
  de merge silencieux qui perdrait un event.
- Reconnexion = échange des ids du dernier event connu, transfert du delta
  uniquement.

## Plateformes

- Apple Watch : `WatchConnectivity`.
- Wear OS : Data Layer API (`MessageClient`, `DataClient`).

Consulter Context7 avant toute implémentation de ces API (voir règle
Context7 dans `CLAUDE.md` — les API peuvent avoir changé depuis
l'entraînement du modèle).

Détail complet : `.claude/skills/playtap-watch-sync/SKILL.md`.
