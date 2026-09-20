import 'package:drift/drift.dart';

import '../../domain/models/origin_device.dart';
import '../../domain/models/session_category.dart';
import '../../domain/models/session_status.dart';
import '../local/app_database.dart';

/// A domain-facing view of a persisted session row — see
/// docs/DATA_MODEL.md. Pure data, no behaviour.
class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.category,
    required this.ownerDevice,
    required this.presetRef,
    required this.startedAt,
    required this.endedAt,
    required this.status,
  });

  final String id;
  final SessionCategory category;
  final OriginDevice ownerDevice;
  final String? presetRef;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
}

/// Pure persistence for session lifecycle metadata. Contains no Score
/// rules and does not itself enforce "one active session" — that is a
/// controller-level orchestration decision (see
/// `features/score_free/free_score_session_controller.dart`).
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  Future<SessionSummary> createSession({
    required String id,
    required SessionCategory category,
    required OriginDevice ownerDevice,
    required String presetRef,
    required DateTime startedAt,
  }) async {
    await _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            schemaVersion: 1,
            category: category.toJson(),
            ownerDevice: ownerDevice.toJson(),
            presetRef: Value(presetRef),
            startedAt: startedAt,
            status: SessionStatus.active.toJson(),
          ),
        );
    return SessionSummary(
      id: id,
      category: category,
      ownerDevice: ownerDevice,
      presetRef: presetRef,
      startedAt: startedAt,
      endedAt: null,
      status: SessionStatus.active,
    );
  }

  Future<SessionSummary?> getSessionById(String id) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// The single active session across *all* categories, if any (see
  /// Release 0.1 / Phase 1B.2 section 27 — exactly one active session at a
  /// time on the phone, Score and Timer share the same invariant).
  Future<SessionSummary?> getActiveSession() async {
    final row =
        await (_db.select(_db.sessions)
              ..where((t) => t.status.equals(SessionStatus.active.toJson())))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Stream<SessionSummary?> watchActiveSession() {
    final query = _db.select(_db.sessions)
      ..where((t) => t.status.equals(SessionStatus.active.toJson()));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  Future<void> completeSession(String id, {required DateTime endedAt}) {
    return (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        status: Value(SessionStatus.completed.toJson()),
        endedAt: Value(endedAt),
      ),
    );
  }

  Future<void> abandonSession(String id, {required DateTime endedAt}) {
    return (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        status: Value(SessionStatus.abandoned.toJson()),
        endedAt: Value(endedAt),
      ),
    );
  }

  /// Completed sessions, most recent first — all categories unless
  /// [category] is given (see docs/DATA_MODEL.md — HistoryEntry is a
  /// derived view, not stored here).
  Future<List<SessionSummary>> getCompletedSessions({
    SessionCategory? category,
  }) async {
    final rows = await _completedSessionsQuery(category).get();
    return rows.map(_toDomain).toList();
  }

  /// Reactive: emits again whenever the completed-sessions result set
  /// changes (same Drift auto-watch pattern as [watchActiveSession]) — lets
  /// Historique stay live instead of freezing on whatever was completed
  /// first (see `features/history/history_page.dart`).
  Stream<List<SessionSummary>> watchCompletedSessions({
    SessionCategory? category,
  }) {
    return _completedSessionsQuery(
      category,
    ).watch().map((rows) => rows.map(_toDomain).toList());
  }

  SimpleSelectStatement<$SessionsTable, Session> _completedSessionsQuery(
    SessionCategory? category,
  ) {
    return _db.select(_db.sessions)
      ..where((t) {
        final completed = t.status.equals(SessionStatus.completed.toJson());
        return category == null
            ? completed
            : completed & t.category.equals(category.toJson());
      })
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
  }

  SessionSummary _toDomain(Session row) => SessionSummary(
    id: row.id,
    category: SessionCategory.fromJson(row.category),
    ownerDevice: OriginDevice.fromJson(row.ownerDevice),
    presetRef: row.presetRef,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    status: SessionStatus.fromJson(row.status),
  );
}
