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

## Contrat minimal — Tennis (Racket Core Phase 1, documenté uniquement)

Aucun code watch n'existe encore pour Tennis (voir CLAUDE.md — le moteur
Dart est figé d'abord). Le contrat minimal qu'une future montre devra
recevoir/envoyer, une fois construit :

**Reçu par la montre** (dérivé de `RacketSessionSnapshot`, voir
`docs/DATA_MODEL.md`) :

```jsonc
{
  "sessionId": "...",
  "rulesetId": "tennis.itf.2026",
  "sideNames": { "side_a": "...", "side_b": "..." },
  "currentDisplayScore": { "side_a": "40", "side_b": "AD" }, // labels dérivés, jamais des points bruts
  "sets": { "side_a": 1, "side_b": 0 },
  "games": { "side_a": 4, "side_b": 3 },
  "server": "side_a",           // ou un ServiceSlot.id en double
  "tieBreakState": null,        // ou { "side_a": 5, "side_b": 4 } pendant un tie-break/Match Tie-break
  "undoAvailable": true
}
```

**Envoyé par la montre** (actions) :

- `POINT_SIDE_A`
- `POINT_SIDE_B`
- `UNDO`

Objectif d'UX montre (voir `playtap-watch-ux`) : un écran minimal du
type

```
30      15

●A

[TAP A] [TAP B]
```

Ce contrat n'engage aucune implémentation actuelle — il fige seulement la
forme attendue pour que le futur code watch (Phase 3) reste un simple
consommateur de `RacketSessionSnapshot`, jamais une réimplémentation des
règles de scoring côté watch au-delà de ce qui est nécessaire à
l'autonomie offline (voir "Fonctionnement watch autonome" ci-dessus et
`playtap-watch-sync`).

## Plateformes

- Apple Watch : `WatchConnectivity`.
- Wear OS : Data Layer API (`MessageClient`, `DataClient`).

Consulter Context7 avant toute implémentation de ces API (voir règle
Context7 dans `CLAUDE.md` — les API peuvent avoir changé depuis
l'entraînement du modèle).

Détail complet : `.claude/skills/playtap-watch-sync/SKILL.md`.
