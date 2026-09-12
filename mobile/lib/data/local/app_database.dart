import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The one built-in preset Phase 1B.1 needs — see `tables.dart` for why
/// Score Libre doesn't get a fresh Preset row per game.
const _freeScorePresetId = 'free_score';

/// schema v1 (Phase 1B.1): sessions/events/presets as described in
/// docs/DATA_MODEL.md. Future schema changes bump [schemaVersion] and add a
/// step to `_migrationStrategy` — do not pre-create empty migrations for
/// versions that don't exist yet.
@DriftDatabase(tables: [Sessions, Events, Presets])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(presets).insert(
        PresetsCompanion.insert(
          id: _freeScorePresetId,
          schemaVersion: 1,
          category: 'SCORE',
          name: 'Score libre',
          config: _freeScoreDefaultConfigJson,
        ),
      );
    },
  );
}

const _freeScoreDefaultConfigJson =
    '{"schemaVersion":1,"mode":"FREE_SCORE","sides":["side_a","side_b"],"defaultIncrement":1}';
