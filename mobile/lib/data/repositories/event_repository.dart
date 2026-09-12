import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/events/session_event.dart';
import '../../domain/models/origin_device.dart';
import '../local/app_database.dart';

/// Pure persistence for the event log — no Score rules here (see
/// `playtap-score-engine`, section "Repositories" in CLAUDE.md/the task
/// brief: repositories map DB <-> domain and handle transactions only).
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  /// Appends one event produced by this phone, assigning it the next
  /// strictly-increasing `originSequence` for (sessionId, PHONE) inside a
  /// transaction — see docs/WATCH_SYNC.md "Event ordering". Never derives
  /// the sequence from the timestamp.
  Future<SessionEvent> appendPhoneEvent({
    required String id,
    required String sessionId,
    required SessionEventType type,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
  }) {
    return _db.transaction(() async {
      final maxSeqQuery = _db.selectOnly(_db.events)
        ..addColumns([_db.events.originSequence.max()])
        ..where(
          _db.events.sessionId.equals(sessionId) &
              _db.events.originDevice.equals(OriginDevice.phone.toJson()),
        );
      final row = await maxSeqQuery.getSingleOrNull();
      final last = row?.read(_db.events.originSequence.max()) ?? 0;
      final nextSequence = last + 1;

      await _db
          .into(_db.events)
          .insert(
            EventsCompanion.insert(
              id: id,
              sessionId: sessionId,
              type: type.toJson(),
              payload: jsonEncode(payload),
              timestamp: timestamp,
              originDevice: OriginDevice.phone.toJson(),
              originSequence: nextSequence,
            ),
          );

      return SessionEvent(
        id: id,
        sessionId: sessionId,
        type: type,
        payload: payload,
        timestamp: timestamp,
        originDevice: OriginDevice.phone,
        originSequence: nextSequence,
      );
    });
  }

  /// All events for a session, ordered for replay. Phase 1B.1 is
  /// single-device (PHONE only), so ordering by `originSequence` alone is
  /// the correct total order — the full cross-device rule in
  /// docs/WATCH_SYNC.md applies once a watch can also write here.
  Future<List<SessionEvent>> getEventsForSession(String sessionId) async {
    final rows =
        await (_db.select(_db.events)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm(expression: t.originSequence)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  SessionEvent _toDomain(Event row) => SessionEvent(
    id: row.id,
    sessionId: row.sessionId,
    type: SessionEventType.fromJson(row.type),
    payload: jsonDecode(row.payload) as Map<String, dynamic>,
    timestamp: row.timestamp,
    originDevice: OriginDevice.fromJson(row.originDevice),
    originSequence: row.originSequence,
  );
}
