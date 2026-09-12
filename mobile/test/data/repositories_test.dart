// Real in-memory SQLite tests — not mocks. See docs/CONFORMANCE.md and the
// project rule: analyze/types passing is not proof of correctness.
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/data/local/app_database.dart';
import 'package:playtap/data/repositories/event_repository.dart';
import 'package:playtap/data/repositories/session_repository.dart';
import 'package:playtap/domain/events/session_event.dart';
import 'package:playtap/domain/models/origin_device.dart';
import 'package:playtap/domain/models/session_category.dart';
import 'package:playtap/domain/models/session_status.dart';

/// Drift/NativeDatabase round-trips a DateTime's exact instant but returns
/// it tagged `isUtc: false` (correct: it's the local-time representation of
/// that instant) — and Dart's `DateTime.==` treats that as unequal to a
/// UTC-tagged value for the very same instant. Compare instants, not tags.
Matcher sameMoment(DateTime expected) => predicate<DateTime>(
  (actual) => actual.isAtSameMomentAs(expected),
  'is at the same moment as $expected',
);

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late EventRepository events;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sessions = SessionRepository(db);
    events = EventRepository(db);
  });

  tearDown(() => db.close());

  group('SessionRepository', () {
    test('createSession persists and is readable by id', () async {
      final created = await sessions.createSession(
        id: 's1',
        category: SessionCategory.score,
        ownerDevice: OriginDevice.phone,
        presetRef: 'free_score',
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final fetched = await sessions.getSessionById('s1');
      expect(fetched, isNotNull);
      expect(fetched!.status, SessionStatus.active);
      expect(fetched.id, created.id);
      expect(fetched.presetRef, 'free_score');
    });

    test(
      'getActiveSession finds the one active session for a category',
      () async {
        await sessions.createSession(
          id: 's1',
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: 'free_score',
          startedAt: DateTime.utc(2026, 1, 1),
        );
        final active = await sessions.getActiveSession(SessionCategory.score);
        expect(active?.id, 's1');
      },
    );

    test('completeSession sets status=COMPLETED and endedAt', () async {
      await sessions.createSession(
        id: 's1',
        category: SessionCategory.score,
        ownerDevice: OriginDevice.phone,
        presetRef: 'free_score',
        startedAt: DateTime.utc(2026, 1, 1),
      );
      await sessions.completeSession(
        's1',
        endedAt: DateTime.utc(2026, 1, 1, 0, 10),
      );

      final fetched = await sessions.getSessionById('s1');
      expect(fetched!.status, SessionStatus.completed);
      expect(fetched.endedAt, sameMoment(DateTime.utc(2026, 1, 1, 0, 10)));
      expect(await sessions.getActiveSession(SessionCategory.score), isNull);
    });

    test(
      'abandonSession sets status=ABANDONED, distinct from COMPLETED',
      () async {
        await sessions.createSession(
          id: 's1',
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: 'free_score',
          startedAt: DateTime.utc(2026, 1, 1),
        );
        await sessions.abandonSession(
          's1',
          endedAt: DateTime.utc(2026, 1, 1, 0, 5),
        );

        final fetched = await sessions.getSessionById('s1');
        expect(fetched!.status, SessionStatus.abandoned);
        expect(
          await sessions.getCompletedSessions(SessionCategory.score),
          isEmpty,
        );
      },
    );

    test('getCompletedSessions returns most recent first', () async {
      for (final n in [1, 2, 3]) {
        await sessions.createSession(
          id: 's$n',
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: 'free_score',
          startedAt: DateTime.utc(2026, 1, n),
        );
        await sessions.completeSession(
          's$n',
          endedAt: DateTime.utc(2026, 1, n, 1),
        );
      }
      final completed = await sessions.getCompletedSessions(
        SessionCategory.score,
      );
      expect(completed.map((s) => s.id).toList(), ['s3', 's2', 's1']);
    });

    test('watchActiveSession emits null after completion', () async {
      await sessions.createSession(
        id: 's1',
        category: SessionCategory.score,
        ownerDevice: OriginDevice.phone,
        presetRef: 'free_score',
        startedAt: DateTime.utc(2026, 1, 1),
      );

      final emissions = <String?>[];
      final sub = sessions
          .watchActiveSession(SessionCategory.score)
          .listen((s) => emissions.add(s?.id));

      await Future<void>.delayed(Duration.zero);
      await sessions.completeSession(
        's1',
        endedAt: DateTime.utc(2026, 1, 1, 0, 1),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions, ['s1', null]);
      await sub.cancel();
    });
  });

  group('EventRepository', () {
    Future<void> seedSession(String id) => sessions.createSession(
      id: id,
      category: SessionCategory.score,
      ownerDevice: OriginDevice.phone,
      presetRef: 'free_score',
      startedAt: DateTime.utc(2026, 1, 1),
    );

    test(
      'appendPhoneEvent assigns strictly increasing originSequence',
      () async {
        await seedSession('s1');
        final e1 = await events.appendPhoneEvent(
          id: 'e1',
          sessionId: 's1',
          type: SessionEventType.sessionStarted,
          payload: const {},
          timestamp: DateTime.utc(2026, 1, 1),
        );
        final e2 = await events.appendPhoneEvent(
          id: 'e2',
          sessionId: 's1',
          type: SessionEventType.pointScored,
          payload: const {'side': 'a', 'amount': 1},
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
        );
        expect(e1.originSequence, 1);
        expect(e2.originSequence, 2);
      },
    );

    test('originSequence is scoped per session', () async {
      await seedSession('s1');
      await seedSession('s2');
      final e1 = await events.appendPhoneEvent(
        id: 'e1',
        sessionId: 's1',
        type: SessionEventType.sessionStarted,
        payload: const {},
        timestamp: DateTime.utc(2026, 1, 1),
      );
      final e2 = await events.appendPhoneEvent(
        id: 'e2',
        sessionId: 's2',
        type: SessionEventType.sessionStarted,
        payload: const {},
        timestamp: DateTime.utc(2026, 1, 1),
      );
      expect(e1.originSequence, 1);
      expect(e2.originSequence, 1); // independent session, own sequence
    });

    test(
      'getEventsForSession returns events in originSequence order',
      () async {
        await seedSession('s1');
        for (var i = 1; i <= 5; i++) {
          await events.appendPhoneEvent(
            id: 'e$i',
            sessionId: 's1',
            type: SessionEventType.pointScored,
            payload: {'side': 'a', 'amount': 1},
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, i),
          );
        }
        final fetched = await events.getEventsForSession('s1');
        expect(fetched.map((e) => e.id).toList(), [
          'e1',
          'e2',
          'e3',
          'e4',
          'e5',
        ]);
        expect(fetched.map((e) => e.originSequence).toList(), [1, 2, 3, 4, 5]);
      },
    );

    test('a duplicate event id is rejected by the database', () async {
      await seedSession('s1');
      await events.appendPhoneEvent(
        id: 'dup',
        sessionId: 's1',
        type: SessionEventType.pointScored,
        payload: const {'side': 'a', 'amount': 1},
        timestamp: DateTime.utc(2026, 1, 1),
      );
      expect(
        () => events.appendPhoneEvent(
          id: 'dup',
          sessionId: 's1',
          type: SessionEventType.pointScored,
          payload: const {'side': 'a', 'amount': 1},
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
        ),
        throwsA(anything),
      );
    });

    test('payload round-trips through JSON exactly', () async {
      await seedSession('s1');
      await events.appendPhoneEvent(
        id: 'e1',
        sessionId: 's1',
        type: SessionEventType.pointScored,
        payload: const {'side': 'side_a', 'amount': 1},
        timestamp: DateTime.utc(2026, 1, 1),
      );
      final fetched = await events.getEventsForSession('s1');
      expect(fetched.single.payload, {'side': 'side_a', 'amount': 1});
    });
  });

  group('Recovery', () {
    test(
      'a fresh AppDatabase instance over the same file sees prior writes',
      () async {
        // Simulates app restart: a new AppDatabase wrapping the same
        // underlying executor must see everything written before "close".
        // (Drift warns about two live wrappers on one executor — expected
        // and safe here since db1 is never written to again after db2 opens.)
        drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final executor = NativeDatabase.memory();
        final db1 = AppDatabase(executor);
        final sessionRepo1 = SessionRepository(db1);
        final eventRepo1 = EventRepository(db1);

        await sessionRepo1.createSession(
          id: 's1',
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: 'free_score',
          startedAt: DateTime.utc(2026, 1, 1),
        );
        await eventRepo1.appendPhoneEvent(
          id: 'e1',
          sessionId: 's1',
          type: SessionEventType.pointScored,
          payload: const {'side': 'a', 'amount': 1},
          timestamp: DateTime.utc(2026, 1, 1),
        );

        // NOTE: this does not close db1 — it reuses the same in-memory
        // executor to simulate "the process died but the file is intact",
        // which is exactly what real recovery relies on (see
        // playtap-offline-first — recovery replays persisted events, it
        // never trusts in-memory state).
        final db2 = AppDatabase(executor);
        final sessionRepo2 = SessionRepository(db2);
        final eventRepo2 = EventRepository(db2);

        final active = await sessionRepo2.getActiveSession(
          SessionCategory.score,
        );
        expect(active?.id, 's1');
        final recoveredEvents = await eventRepo2.getEventsForSession('s1');
        expect(recoveredEvents, hasLength(1));
        expect(recoveredEvents.single.payload, {'side': 'a', 'amount': 1});

        await db1.close();
      },
    );
  });
}
