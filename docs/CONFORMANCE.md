# PlayTap — Conformance Contracts

## Pourquoi

Le Score Engine, le Timer Engine, l'Interval Engine et le Workout Engine
(voir `playtap-score-engine`, `playtap-timer-engine`,
`playtap-interval-engine`, `playtap-workout-engine`) sont conceptuellement
uniques, mais **implémentés dans trois langages différents** : Dart
(mobile), Swift (Apple Watch), Kotlin (Wear OS). Cette duplication est
nécessaire pour que chaque montre reste autonome (voir
`playtap-watch-sync` — "une montre doit pouvoir continuer une session si
le téléphone disparaît").

Trois implémentations indépendantes des mêmes règles créent un risque
réel de **divergence silencieuse** (ex : Swift gère la deuce différemment
de Dart, ou Kotlin dérive un `remaining` légèrement différent). Un bug de
ce type est difficile à détecter par la revue de code seule, car chaque
implémentation "a l'air correcte" isolément.

`/contracts` résout ce problème : ce sont des **fixtures indépendantes du
langage**, servant de suite de tests de conformité partagée. Si Dart,
Swift et Kotlin passent tous les mêmes fixtures, ils sont garantis
équivalents sur les cas couverts.

## Format général

Chaque fixture est un fichier JSON dans `/contracts/<engine>/<id>.json` où
`<engine>` ∈ {`score`, `timer`, `interval`, `workout`, `match`,
`shootout`, `racket`}.

`match` et `shootout` (Phase Sports 2 — Basketball/Football/Futsal)
peuvent utiliser **soit** `expected` (état final unique, pour vérifier des
transitions de phase/période — comme `score`) **soit**
`expectedCheckpoints` (plusieurs instants `atMs` — comme `timer`), selon
ce que le cas vérifie : une fixture `match` de recovery/pause/background
veut plusieurs checkpoints temporels, une fixture de transition de phase
(ex. égalité → prolongation → décision) veut un état final unique.

`racket` (Racket Core Phase 1 — Tennis) suit le même principe avec sa
propre clé de checkpoint : `expected` pour un état final unique (la
majorité des cas — jeu/set/tie-break/match/undo/recovery), ou
`expectedCheckpoints` avec `afterPointNumber` (nombre d'events du tableau
`events` à rejouer, 1-indexé — pas seulement le nombre de points de
tie-break, l'index porte sur le tableau `events` complet) plutôt qu'un
`atMs`, pour vérifier un déroulé point par point sans dépendre d'un état
final unique (ex. `tennis_tiebreak_service_rotation` : rotation du
service vérifiée à chaque point du tie-break). Voir
`mobile/test/conformance/racket_conformance_test.dart`.

Structure commune :

```jsonc
{
  "schemaVersion": 1,
  "id": "nom_unique_du_cas",
  "engine": "score | timer | interval | workout",
  "description": "ce que ce cas vérifie et pourquoi",
  "config": { /* ScoreRule | TimerSpec | IntervalProgram | WorkoutSequence,
                 avec son propre schemaVersion — voir DATA_MODEL.md */ },
  "events": [ /* INPUT EVENTS : séquence ordonnée, rejouée telle quelle */ ],
  "expected": { /* EXPECTED STATE, cas score : état final unique */ },
  "expectedCheckpoints": [ /* EXPECTED STATE, cas timer/interval :
                              plusieurs instants "atMs" à vérifier */ ]
}
```

- **`config`** : la configuration du moteur pour ce cas (voir
  `docs/DATA_MODEL.md` pour la forme de chaque type).
- **`events`** (INPUT EVENTS) : chaque event porte `id` (UUID unique),
  `originDevice`, `originSequence` (voir section "Event ordering" de
  `docs/WATCH_SYNC.md`), `tOffsetMs` (temps relatif au démarrage du cas,
  jamais un timestamp absolu — les fixtures doivent être reproductibles
  indépendamment de la date d'exécution), `type`, `payload`.
- **EXPECTED STATE** : soit un état final unique (`expected`, typiquement
  pour le Score Engine où l'on rejoue tous les events puis vérifie l'état
  résultant), soit plusieurs instants de vérification (`expectedCheckpoints`,
  pour Timer/Interval où l'on veut vérifier l'état à différents `atMs`
  sans dépendre d'un déroulé temps réel).

## Versioning

- Chaque fixture porte son propre `schemaVersion` (le format de la
  fixture elle-même).
- Chaque `config` embarqué porte le `schemaVersion` de son propre type
  (`ScoreRule`, `MatchRule`, `TimerSpec`, `IntervalProgram`,
  `WorkoutSequence` — voir `docs/DATA_MODEL.md`). Une fixture `match`
  embarque `config.matchRule` (le `MatchRule` complet, incluant son propre
  `scoreRule`) ; une fixture `shootout` embarque `config.shootoutRule` +
  `config.sideIds`.
- Une évolution incompatible d'un format de `config` nécessite
  d'incrémenter son `schemaVersion` et de fournir soit une migration, soit
  de nouvelles fixtures versionnées côte à côte (jamais de fixture
  existante réécrite silencieusement avec une nouvelle sémantique).
- Le `schemaVersion` du fichier fixture lui-même n'est incrémenté que si
  la structure générale (`events`/`expected`/`expectedCheckpoints`) change.

## Exécution par plateforme

Chaque plateforme doit fournir un petit runner qui :

1. Charge une fixture JSON.
2. Construit le moteur natif (Score/Timer/Interval/Workout Engine) à
   partir de `config`.
3. Rejoue `events` dans l'ordre (voir la règle de tri dans
   `docs/WATCH_SYNC.md` — par `originSequence` puis `id`, jamais par
   timestamp seul entre appareils différents ; au sein d'une même fixture
   à un seul device, l'ordre du tableau JSON fait foi).
4. Pour `expected` : compare l'état final au bloc attendu.
5. Pour `expectedCheckpoints` : pour chaque entrée, évalue l'état du
   moteur "comme si `now = atMs`" (voir `playtap-timer-engine` — calcul
   par `elapsed(now)`, jamais par relecture d'un compteur tické) et
   compare au bloc attendu.

- **Dart/Flutter** : runner de test (`flutter test`) chargeant les fixtures
  depuis `/contracts`.
- **Swift/watchOS** : cible de test XCTest chargeant les mêmes fichiers
  JSON (via un chemin partagé ou une copie de build).
- **Kotlin/Wear OS** : test JVM/Android chargeant les mêmes fichiers JSON.

Les trois runners doivent produire un verdict pass/fail identique pour
chaque fixture. Consulter Context7 avant d'implémenter le chargement JSON
natif dans chaque plateforme (voir règle Context7, `CLAUDE.md`).

## Interdiction

**Aucune plateforme n'a le droit d'implémenter une règle de moteur
différemment des deux autres sans faire évoluer le contrat en premier.**
Si un comportement diverge (ex : gestion d'un cas limite non couvert), la
correction se fait dans cet ordre :

1. Ajouter ou corriger la fixture dans `/contracts` pour capturer le cas.
2. Faire échouer volontairement les implémentations concernées face à
   cette fixture (confirmer qu'elle détecte bien le problème).
3. Corriger les implémentations jusqu'à ce que toutes passent la fixture.

Ne jamais corriger une implémentation en se basant uniquement sur "ça a
l'air juste" sans passer par une fixture — voir la règle de vérification
dans `CLAUDE.md`.

## Note — fixture corrigée (2026-09-22)

`contracts/score/target_score_win_by_two.json` avait été écrite avant
toute implémentation réelle de TARGET_SCORE (systématiquement `skip`
jusqu'à la Phase Sports 1) et sa séquence d'events ne pouvait
mathématiquement pas produire le score final qu'elle revendiquait elle-même
(12-10 à partir de 12 events à 1 point). Corrigée en étendant la séquence
à 22 events cohérents aboutissant au même état final revendiqué à
l'origine, exactement le processus décrit ci-dessus ("Interdiction").
Les nouvelles fixtures `team_score_basic` et `petanque_*` (voir
`docs/SPORT_RULES.md`, `docs/DATA_MODEL.md`) suivent le même format,
vérifiées passantes pour de vrai (jamais un ancien `skip` transformé en
`pass` sans implémentation réelle derrière).

## Note — fixtures Tennis déplacées vers `/contracts/racket` (Racket Core Phase 1)

`contracts/score/tennis_basic_progression.json` et
`contracts/score/tennis_deuce_advantage.json` avaient été écrites avant
toute implémentation réelle de Tennis, avec un `config.mode:
"SEQUENTIAL_SCORE"` jamais implémenté — systématiquement `skip` par
`score_conformance_test.dart`, jamais un vrai `pass`. La décision
architecturale de Racket Core Phase 1 (voir `docs/DATA_MODEL.md`
"RacketMatchRule") retient que Tennis n'est pas un mode `ScoreRule` mais
un moteur séparé (`RacketMatchRule`/`RacketEngine`) : ces deux fixtures
ont donc été retirées de `/contracts/score` (leur `config` n'a plus de
sens dans ce dossier) plutôt qu'adaptées sur place, et remplacées par 16
fixtures dans le nouveau dossier `/contracts/racket` couvrant les mêmes
cas (progression 0/15/30/40, deuce/avantage) et bien plus (No-Ad, sets,
tie-break, Match Tie-break, Best of, service simple/double, rotation de
service au tie-break, undo à chaque niveau, recovery) — toutes vérifiées
passantes pour de vrai par `racket_conformance_test.dart`, exactement le
processus décrit ci-dessus ("Interdiction").
