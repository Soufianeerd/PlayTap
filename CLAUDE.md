# PlayTap

PlayTap est une application mobile et smartwatch sportive universelle.

Sa promesse :

> "If I need to count or time something during sport, PlayTap can probably do it."

Le produit couvre notamment :

**SCORES** — Tennis, Padel, Tennis de table, Badminton, Pétanque, Basketball,
Football / Futsal, Volleyball, Score libre

**TIMERS** — Chronomètre, Countdown, Lap timer, Sprint timer

**TRAINING** — Fractionné, HIIT, Tabata, Circuit Training, Gainage, EMOM,
AMRAP, Boxing Timer, Musculation / temps de repos

**CUSTOM** — Compteur personnalisé, Timer personnalisé, Workout personnalisé,
Circuit personnalisé

Vision produit détaillée : voir `docs/PRODUCT_SPEC.md` et le skill
`playtap-product`.

## Principes produit

### Phone-first for configuration

Le smartphone sert principalement à : choisir, configurer, personnaliser,
créer, consulter l'historique.

### Watch-first during activity

La montre sert principalement à : démarrer, compter, chronométrer, annuler,
faire pause, recevoir les signaux, passer d'une phase à une autre.

Pendant une activité sportive, l'UX montre doit être extrêmement simple.
Voir le skill `playtap-watch-ux`.

## Offline first

Le MVP PlayTap doit fonctionner sans Internet.

- Aucun backend nécessaire.
- Aucun compte nécessaire.
- Aucune authentification utilisateur.
- Aucun cloud obligatoire.
- Aucune dépendance réseau pour : score, timer, séance, historique local,
  reprise de session.

Internet ne doit jamais être nécessaire pour terminer une activité.
Voir le skill `playtap-offline-first`.

## Architecture générique

**INTERDICTION** d'implémenter chaque sport comme une logique totalement
séparée.

PlayTap doit reposer principalement sur ces moteurs génériques :

- Score Engine
- Timer Engine
- Interval Engine
- Workout Sequence Engine
- Session Engine
- Event Engine
- History Engine

Les sports et entraînements sont majoritairement des **presets** de ces
moteurs. Exemples :

- Padel et Tennis → même famille de Score Engine
- Tabata → Interval Engine : 20 sec work / 10 sec rest x8
- Sprint 30/30 → Interval Engine : 30 sec sprint / 30 sec recovery x10
- Gainage → Timer / Workout Engine
- Basket → Score Engine avec incréments 1/2/3

Détails moteur par moteur : skills `playtap-score-engine`,
`playtap-timer-engine`, `playtap-interval-engine`, `playtap-workout-engine`.

## Technologies

Architecture de dossiers prévue :

```
/mobile        Flutter — iOS + Android
/apple-watch   SwiftUI / watchOS
/wear-os       Kotlin + Compose for Wear OS
/contracts     fixtures JSON de conformité inter-plateformes
/docs          documentation
/.claude       instructions et skills PlayTap
```

**Mobile (Flutter)** : Dart, Flutter, Riverpod, go_router, stockage
**SQLite via Drift (décision définitive, voir `docs/DATA_MODEL.md`)**.

**Apple Watch** : Swift, SwiftUI, WatchConnectivity.

**Wear OS** : Kotlin, Compose for Wear OS (Material3), Data Layer API
lorsque nécessaire.

## Outils à utiliser

### Context7

Lorsque tu travailles avec une API, librairie ou SDK dont la version peut
avoir changé, consulte Context7 avant d'implémenter. Cela s'applique
particulièrement à : Flutter, Dart, Riverpod, Drift, SwiftUI, watchOS,
WatchConnectivity, Kotlin, Jetpack Compose, Compose for Wear OS, Android
APIs.

Ne suppose jamais qu'une API mémorisée est toujours actuelle.

### Figma

Lorsqu'une maquette Figma officielle PlayTap existe : inspecte-la avec
Figma MCP, récupère ses composants, ses spacing, ses tokens, respecte la
hiérarchie. Ne réinterprète pas arbitrairement le design.

### XcodeBuildMCP

Pour les targets Apple : ne considère jamais qu'un changement important
est terminé sans essayer de compiler lorsque l'environnement le permet.

### Mobile MCP

Utilise Mobile MCP pour tester les parcours utilisateurs sur simulateur ou
appareil lorsqu'une feature est implémentée (ouvrir l'app, démarrer une
activité, toucher les boutons, vérifier les états, prendre un screenshot,
inspecter les crashes/logs).

### GitHub

Utilise GitHub pour repository, branches, commits, issues, pull requests,
Actions. Ne push jamais de secrets.

Outils principaux pour PlayTap, dans cet ordre de priorité : Context7,
GitHub, Figma, XcodeBuildMCP, Mobile MCP. Ne pas utiliser automatiquement
les connecteurs sans rapport avec PlayTap (Gmail, Calendar, Canva, Lovable,
Notion, etc.).

## Règle de vérification (obligatoire)

**NEVER CLAIM A FEATURE IS COMPLETE ONLY BECAUSE THE CODE LOOKS CORRECT.**

Lorsque les outils le permettent, dans cet ordre :

1. Compile.
2. Analyse (`flutter analyze`, warnings Swift/Kotlin...).
3. Exécute les tests.
4. Lance l'application.
5. Teste le parcours utilisateur concerné.
6. Vérifie les logs.
7. Corrige les erreurs.
8. Seulement ensuite, déclare la feature terminée.

## Skills métier PlayTap

Voir `.claude/skills/` :

- `playtap-product` — vision produit, MVP, définition de done
- `playtap-score-engine` — moteur de score générique
- `playtap-timer-engine` — moteur de temps fiable
- `playtap-interval-engine` — moteur d'intervalles (work/rest)
- `playtap-workout-engine` — séquences d'entraînement
- `playtap-sports-rules` — presets sportifs V1
- `playtap-watch-ux` — règles UX montre
- `playtap-offline-first` — persistance locale
- `playtap-watch-sync` — synchronisation phone/watch
- `playtap-release-gate` — checklist avant release

## Documentation

Voir `docs/` : `PRODUCT_SPEC.md`, `ARCHITECTURE.md`, `DATA_MODEL.md`,
`SPORT_RULES.md`, `WATCH_SYNC.md`, `MVP.md`, `ROADMAP.md`,
`RELEASE_CHECKLIST.md`, `CONFORMANCE.md`, `RELEASE_0_1.md`.

## Contrats multi-plateformes

Le Score/Timer/Interval/Workout Engine sont réimplémentés en Dart, Swift
et Kotlin (voir "Architecture générique" ci-dessus et
`playtap-watch-sync` — la watch doit fonctionner seule). Pour empêcher
toute divergence de comportement entre plateformes, `/contracts` contient
des fixtures JSON indépendantes du langage (input events + état attendu)
que chaque implémentation (Dart, Swift, Kotlin) doit rejouer et valider à
l'identique. Détail complet : `docs/CONFORMANCE.md`.

**Interdiction d'implémenter une règle différemment selon la plateforme
sans faire évoluer le contrat correspondant en premier.**

## Git & sécurité

- Ne jamais commiter de secrets (`.env`, clés API, certificats, provisioning
  profiles, keystores).
- Ne jamais créer de remote GitHub distant sans validation explicite de
  l'utilisateur.
- Vérifier `git status` avant tout commit large pour éviter d'inclure des
  fichiers indésirables.

### Repository parent (danger connu)

Il existe un dépôt Git **parent** dans le home directory
(`/Users/soufianeelrhadi`), appartenant à un projet sans rapport
(`cabinetDrELOMRI`). PlayTap a son propre dépôt Git local
(`/Users/soufianeelrhadi/Projets/Apps/PlayTap/.git`), qui doit toujours
être le seul dépôt concerné par le travail sur PlayTap.

Règles absolues :

- **Ne jamais lancer de mutation Git dans le repository parent**
  (`git add`, `git commit`, `git push`, etc. exécutés depuis un chemin
  hors de `PlayTap/` ou dont le root résoudrait au home directory).
- **Ne jamais stager un fichier situé en dehors du repository PlayTap.**
- **Avant toute opération Git importante** (`add -A`, `commit`, `push`,
  `reset`, ou toute commande qui touche l'index/l'historique), vérifier
  que `git rev-parse --show-toplevel` retourne exactement le chemin de
  `PlayTap/` — jamais le home directory. Si ce n'est pas le cas, s'arrêter
  et alerter l'utilisateur avant de continuer.
