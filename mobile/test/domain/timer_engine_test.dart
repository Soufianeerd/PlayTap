import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/timer_engine.dart';
import 'package:playtap/domain/events/timer_engine_event.dart';
import 'package:playtap/domain/models/timer_mode.dart';
import 'package:playtap/domain/models/timer_spec.dart';
import 'package:playtap/domain/models/timer_status.dart';

TimerEngineEvent started(String id, int atMs) =>
    TimerEngineEvent(id: id, type: TimerEngineEventType.started, atMs: atMs);
TimerEngineEvent paused(String id, int atMs) =>
    TimerEngineEvent(id: id, type: TimerEngineEventType.paused, atMs: atMs);
TimerEngineEvent resumed(String id, int atMs) =>
    TimerEngineEvent(id: id, type: TimerEngineEventType.resumed, atMs: atMs);
TimerEngineEvent lap(String id, int atMs) => TimerEngineEvent(
  id: id,
  type: TimerEngineEventType.lapRecorded,
  atMs: atMs,
);
TimerEngineEvent completed(String id, int atMs) =>
    TimerEngineEvent(id: id, type: TimerEngineEventType.completed, atMs: atMs);

TimerSpec stopwatchSpec() =>
    const TimerSpec(schemaVersion: 1, mode: TimerMode.stopwatch);
TimerSpec countdownSpec(int durationMs) => TimerSpec(
  schemaVersion: 1,
  mode: TimerMode.countdown,
  durationTargetMs: durationMs,
);
TimerSpec lapTimerSpec() =>
    const TimerSpec(schemaVersion: 1, mode: TimerMode.lapTimer);

void main() {
  group('TimerEngine — STOPWATCH', () {
    test('initial state before any event: paused, elapsed 0', () {
      final state = TimerEngine.replay(stopwatchSpec(), [], nowMs: 5000);
      expect(state.status, TimerStatus.paused);
      expect(state.elapsedMs, 0);
      expect(state.remainingMs, isNull);
    });

    test('start then elapsed after 1s', () {
      final state = TimerEngine.replay(stopwatchSpec(), [
        started('e1', 0),
      ], nowMs: 1000);
      expect(state.status, TimerStatus.running);
      expect(state.elapsedMs, 1000);
    });

    test('elapsed after 1 hour — long durations work without drift', () {
      const oneHourMs = 3600 * 1000;
      final state = TimerEngine.replay(stopwatchSpec(), [
        started('e1', 0),
      ], nowMs: oneHourMs);
      expect(state.elapsedMs, oneHourMs);
      expect(state.status, TimerStatus.running);
    });

    test('pause freezes elapsed regardless of how much time passes after', () {
      final events = [started('e1', 0), paused('e2', 10000)];
      final at12s = TimerEngine.replay(stopwatchSpec(), events, nowMs: 12000);
      final at999s = TimerEngine.replay(stopwatchSpec(), events, nowMs: 999000);
      expect(at12s.elapsedMs, 10000);
      expect(at999s.elapsedMs, 10000);
      expect(at12s.status, TimerStatus.paused);
    });

    test('resume continues accumulating from where it left off', () {
      final events = [
        started('e1', 0),
        paused('e2', 10000),
        resumed('e3', 15000),
      ];
      final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 20000);
      expect(
        state.elapsedMs,
        15000,
      ); // matches contracts/timer/pause_resume.json
      expect(state.status, TimerStatus.running);
    });

    test('multiple pause/resume cycles accumulate correctly', () {
      final events = [
        started('e1', 0),
        paused('e2', 5000),
        resumed('e3', 8000),
        paused('e4', 13000),
        resumed('e5', 20000),
      ];
      // active windows: [0,5000] + [8000,13000] + [20000, now]
      final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 25000);
      expect(state.elapsedMs, 5000 + 5000 + 5000);
    });

    test(
      'completed via SESSION_COMPLETED freezes elapsed and ignores anything after',
      () {
        final events = [
          started('e1', 0),
          TimerEngineEvent(
            id: 'e2',
            type: TimerEngineEventType.completed,
            atMs: 9000,
          ),
          started('e3', 20000), // must be ignored: already completed
        ];
        final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 50000);
        expect(state.status, TimerStatus.completed);
        expect(state.elapsedMs, 9000);
      },
    );
  });

  group('TimerEngine — COUNTDOWN', () {
    test('initial state equals the configured duration', () {
      final state = TimerEngine.replay(countdownSpec(60000), [], nowMs: 0);
      expect(state.remainingMs, 60000);
    });

    test('contracts/timer/countdown_basic.json checkpoints', () {
      final spec = countdownSpec(60000);
      final events = [started('e1', 0)];

      final at30s = TimerEngine.replay(spec, events, nowMs: 30000);
      expect(at30s.remainingMs, 30000);
      expect(at30s.status, TimerStatus.running);

      final at60s = TimerEngine.replay(spec, events, nowMs: 60000);
      expect(at60s.remainingMs, 0);
      expect(at60s.status, TimerStatus.completed);

      final at65s = TimerEngine.replay(spec, events, nowMs: 65000);
      expect(at65s.remainingMs, 0);
      expect(at65s.status, TimerStatus.completed);
    });

    test('pause then resume during a countdown', () {
      final events = [
        started('e1', 0),
        paused('e2', 20000),
        resumed('e3', 30000),
      ];
      final state = TimerEngine.replay(
        countdownSpec(60000),
        events,
        nowMs: 40000,
      );
      // elapsed = 20000 (before pause) + 10000 (after resume) = 30000
      expect(state.remainingMs, 30000);
      expect(state.status, TimerStatus.running);
    });

    test(
      'remaining is exactly zero, never negative, arbitrarily far past target',
      () {
        final state = TimerEngine.replay(countdownSpec(10000), [
          started('e1', 0),
        ], nowMs: 999999999);
        expect(state.remainingMs, 0);
        expect(state.elapsedMs, 10000);
      },
    );

    test(
      'completion is idempotent: a duplicate TIMER_COMPLETED changes nothing',
      () {
        final events = [
          started('e1', 0),
          completed('e2', 60000),
          completed('e2', 60000), // duplicate id: no-op
        ];
        final state = TimerEngine.replay(
          countdownSpec(60000),
          events,
          nowMs: 70000,
        );
        expect(state.status, TimerStatus.completed);
        expect(state.remainingMs, 0);
      },
    );

    test(
      'an invalid TimerSpec (COUNTDOWN with no duration) is rejected at construction',
      () {
        expect(
          () => TimerSpec(schemaVersion: 1, mode: TimerMode.countdown),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('TimerEngine — LAP_TIMER', () {
    test('lap 1 records cumulative and split equal to elapsed since start', () {
      final events = [started('e1', 0), lap('e2', 4320)];
      final state = TimerEngine.replay(lapTimerSpec(), events, nowMs: 4320);
      expect(state.laps, hasLength(1));
      expect(state.laps[0].cumulativeElapsedMs, 4320);
      expect(state.laps[0].splitMs, 4320);
      expect(state.laps[0].lapNumber, 1);
    });

    test('lap 2 split is the delta since lap 1', () {
      final events = [started('e1', 0), lap('e2', 4320), lap('e3', 8206)];
      final state = TimerEngine.replay(lapTimerSpec(), events, nowMs: 8206);
      expect(state.laps, hasLength(2));
      expect(state.laps[1].cumulativeElapsedMs, 8206);
      expect(state.laps[1].splitMs, 8206 - 4320);
    });

    test('laps recorded across a pause/resume still derive correct splits', () {
      final events = [
        started('e1', 0),
        lap('e2', 5000),
        paused('e3', 6000),
        resumed('e4', 16000), // 10s paused, excluded from elapsed
        lap(
          'e5',
          20000,
        ), // elapsed at this lap = 5000(pre) + 4000(post) = 9000...
      ];
      final state = TimerEngine.replay(lapTimerSpec(), events, nowMs: 20000);
      expect(state.laps[0].cumulativeElapsedMs, 5000);
      // accumulated before 2nd lap: 6000 (0->6000 running) + (20000-16000) = 10000
      expect(state.laps[1].cumulativeElapsedMs, 10000);
      expect(state.laps[1].splitMs, 5000);
    });

    test('recovery preserves previously recorded laps and allows new ones', () {
      final events = [
        started('e1', 0),
        lap('e2', 3000),
        lap('e3', 7000),
        // simulate recovery: engine just replays the same log plus a new lap
        lap('e4', 12000),
      ];
      final state = TimerEngine.replay(lapTimerSpec(), events, nowMs: 12000);
      expect(state.laps, hasLength(3));
      expect(state.laps.map((l) => l.lapNumber), [1, 2, 3]);
    });
  });

  group('TimerEngine — general event sourcing guarantees', () {
    test(
      'replay is deterministic: same events always produce the same state',
      () {
        final events = [
          started('e1', 0),
          paused('e2', 5000),
          resumed('e3', 8000),
        ];
        final spec = stopwatchSpec();
        final first = TimerEngine.replay(spec, events, nowMs: 12000);
        final second = TimerEngine.replay(spec, events, nowMs: 12000);
        expect(first, second);
      },
    );

    test('a duplicate event id anywhere in the log is applied only once', () {
      final events = [started('e1', 0), paused('e2', 5000), paused('e2', 5000)];
      final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 9000);
      expect(state.elapsedMs, 5000);
      expect(state.status, TimerStatus.paused);
    });

    test('pausing an already-paused timer is a no-op', () {
      final events = [started('e1', 0), paused('e2', 5000), paused('e3', 7000)];
      final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 9000);
      expect(state.elapsedMs, 5000); // second PAUSED had nothing to pause
    });

    test('resuming an already-running timer is a no-op', () {
      final events = [started('e1', 0), resumed('e2', 5000)];
      final state = TimerEngine.replay(stopwatchSpec(), events, nowMs: 9000);
      expect(state.elapsedMs, 9000); // unaffected by the spurious resume
    });

    test('pausing before any start is a no-op, not a crash', () {
      final state = TimerEngine.replay(stopwatchSpec(), [
        paused('e1', 1000),
      ], nowMs: 5000);
      expect(state.status, TimerStatus.paused);
      expect(state.elapsedMs, 0);
    });

    test('a lap before start is ignored, not a crash', () {
      final state = TimerEngine.replay(lapTimerSpec(), [
        lap('e1', 1000),
      ], nowMs: 5000);
      expect(state.laps, isEmpty);
    });

    test('any event after completion is ignored', () {
      final events = [
        started('e1', 0),
        completed('e2', 5000),
        lap('e3', 6000),
        paused('e4', 7000),
      ];
      final state = TimerEngine.replay(lapTimerSpec(), events, nowMs: 10000);
      expect(state.status, TimerStatus.completed);
      expect(state.laps, isEmpty);
      expect(state.elapsedMs, 5000);
    });
  });
}
