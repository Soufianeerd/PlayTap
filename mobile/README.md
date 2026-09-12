# PlayTap — Mobile

L'app phone (iOS + Android) : configuration, personnalisation et
historique des activités. Pendant l'effort, l'exécution passe
principalement par la watch — voir `../CLAUDE.md`.

## Stack

Flutter + Dart, Riverpod (state), go_router (navigation), Drift/SQLite
(persistance locale — décision définitive, voir `../docs/DATA_MODEL.md`).

## Commandes

```
flutter pub get
flutter analyze
flutter test
flutter run
```

Après toute modification de `lib/data/local/tables.dart` ou
`app_database.dart`, régénérer le code Drift :

```
dart run build_runner build --delete-conflicting-outputs
```

**Cible réelle : Android/iOS/desktop, pas le web.** Drift utilise
`dart:ffi` (via `package:sqlite3`), indisponible en compilation web — le
web reste une commodité de dev ponctuelle (voir `../CLAUDE.md`), jamais
une cible produit ni un terrain de vérification pour des features qui
touchent la persistance.

## Architecture (`lib/`)

```
app/        point d'entrée, router, providers Riverpod, design tokens (theme/)
core/       utilitaires transverses (ids, time, errors)
domain/     modèles, events, moteurs purs (Score Engine, ...) — testables
            sans Flutter/Riverpod/Drift
data/       persistance locale (Drift : tables, connexion, repositories)
features/   écrans par domaine (home, activities, score_free, history, settings)
```

## Principes

- Offline-first : aucune feature essentielle ne dépend d'Internet.
- Aucun backend requis pour le MVP.

Détails : `../CLAUDE.md` et `../docs/ARCHITECTURE.md`.
