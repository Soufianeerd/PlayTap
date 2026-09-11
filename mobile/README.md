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

## Architecture (`lib/`)

```
app/        point d'entrée, router, design tokens (theme/)
core/       utilitaires transverses (ids, time, errors)
domain/     modèles, events, moteurs (Score/Timer/Interval/Workout)
data/       persistance locale (Drift)
features/   écrans par domaine (home, activities, session, history, settings)
```

## Principes

- Offline-first : aucune feature essentielle ne dépend d'Internet.
- Aucun backend requis pour le MVP.

Détails : `../CLAUDE.md` et `../docs/ARCHITECTURE.md`.
