import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Built-in presets — see `tables.dart` for why these don't get a fresh
/// Preset row per session: participant names (Score) and configured
/// duration (Countdown) are session-specific and live in that session's
/// `SESSION_STARTED` event instead.
const _freeScorePresetId = 'free_score';
const _stopwatchPresetId = 'stopwatch';
const _countdownPresetId = 'countdown';
const _lapTimerPresetId = 'lap_timer';

/// schema v1 (Phase 1B.1 + 1B.2): sessions/events/presets as described in
/// docs/DATA_MODEL.md. Timer (Phase 1B.2) reuses this schema as-is — no new
/// table or column was needed, so there is no v2 (see docs/DATA_MODEL.md
/// "Timer Engine — pas de migration"). Future schema changes bump
/// [schemaVersion] and add a step to `_migrationStrategy` — do not
/// pre-create empty migrations for versions that don't exist yet.
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
      await into(presets).insert(
        PresetsCompanion.insert(
          id: _stopwatchPresetId,
          schemaVersion: 1,
          category: 'TIMER',
          name: 'Chronomètre',
          config: _stopwatchDefaultConfigJson,
        ),
      );
      await into(presets).insert(
        PresetsCompanion.insert(
          id: _countdownPresetId,
          schemaVersion: 1,
          category: 'TIMER',
          name: 'Countdown',
          config: _countdownDefaultConfigJson,
        ),
      );
      await into(presets).insert(
        PresetsCompanion.insert(
          id: _lapTimerPresetId,
          schemaVersion: 1,
          category: 'TIMER',
          name: 'Lap Timer',
          config: _lapTimerDefaultConfigJson,
        ),
      );
    },
  );
}

const _freeScoreDefaultConfigJson =
    '{"schemaVersion":1,"mode":"FREE_SCORE","sides":["side_a","side_b"],"defaultIncrement":1}';
const _stopwatchDefaultConfigJson = '{"schemaVersion":1,"mode":"STOPWATCH"}';
const _countdownDefaultConfigJson =
    '{"schemaVersion":1,"mode":"COUNTDOWN","durationTargetMs":60000}';
const _lapTimerDefaultConfigJson = '{"schemaVersion":1,"mode":"LAP_TIMER"}';
