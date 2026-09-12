import 'package:drift/drift.dart';

/// See docs/DATA_MODEL.md — lifecycle metadata only. The score itself is
/// never stored here: it is always derived by replaying [Events].
class Sessions extends Table {
  TextColumn get id => text()();
  IntColumn get schemaVersion => integer()();
  TextColumn get category => text()();
  TextColumn get ownerDevice => text()();
  TextColumn get presetRef => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only event log — the actual source of truth for session state
/// (see `playtap-score-engine`). `payload` is JSON-encoded: Drift/SQLite
/// has no native JSON column, and the payload shape already varies per
/// `type` (see docs/CONFORMANCE.md), so a typed column per field would
/// mean a different schema per event type.
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get originDevice => text()();
  IntColumn get originSequence => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    // See playtap-watch-sync — two events from the same device in the same
    // session must never share an originSequence.
    {sessionId, originDevice, originSequence},
  ];
}

/// See docs/DATA_MODEL.md. Minimal for Phase 1B.1: a single built-in
/// "free_score" row (seeded in `AppDatabase`) — Score Libre sessions carry
/// their own participant names in their `SESSION_STARTED` event rather
/// than in a per-game Preset row (see `data/local/app_database.dart`).
class Presets extends Table {
  TextColumn get id => text()();
  IntColumn get schemaVersion => integer()();
  TextColumn get category => text()();
  TextColumn get name => text()();
  TextColumn get config => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
