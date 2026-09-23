import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/shot_clock_engine.dart';
import 'package:playtap/domain/events/shot_clock_engine_event.dart';
import 'package:playtap/domain/models/shot_clock_rule.dart';
import 'package:playtap/domain/models/timer_status.dart';

const _rule = ShotClockRule(
  schemaVersion: 1,
  defaultDurationMs: 24000,
  shortResetDurationMs: 14000,
);

ShotClockEngineEvent started(String id, int atMs) => ShotClockEngineEvent(
  id: id,
  type: ShotClockEngineEventType.started,
  atMs: atMs,
  payload: const {},
);

ShotClockEngineEvent paused(String id, int atMs) => ShotClockEngineEvent(
  id: id,
  type: ShotClockEngineEventType.paused,
  atMs: atMs,
  payload: const {},
);

ShotClockEngineEvent reset(String id, int atMs, int durationMs) =>
    ShotClockEngineEvent(
      id: id,
      type: ShotClockEngineEventType.reset,
      atMs: atMs,
      payload: {'durationMs': durationMs},
    );

ShotClockEngineEvent completed(String id, int atMs) => ShotClockEngineEvent(
  id: id,
  type: ShotClockEngineEventType.completed,
  atMs: atMs,
  payload: const {},
);

ShotClockEngineEvent undo(
  String id,
  int atMs, {
  required String targetEventId,
}) => ShotClockEngineEvent(
  id: id,
  type: ShotClockEngineEventType.undo,
  atMs: atMs,
  payload: {'targetEventId': targetEventId},
);

void main() {
  group('ShotClockEngine', () {
    test('initial state: paused at the default duration', () {
      final state = ShotClockEngine.replay(_rule, [], nowMs: 0);
      expect(state.status, TimerStatus.paused);
      expect(state.remainingMs, 24000);
      expect(state.elapsedMs, 0);
    });

    test(
      'SHOT_CLOCK_RESET(24000) alone leaves it paused at 24s (not auto-started)',
      () {
        final state = ShotClockEngine.replay(_rule, [
          reset('e1', 0, 24000),
        ], nowMs: 5000);
        expect(state.status, TimerStatus.paused);
        expect(state.remainingMs, 24000);
      },
    );

    test('reset then start counts down from the reset duration', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
      ], nowMs: 5000);
      expect(state.status, TimerStatus.running);
      expect(state.elapsedMs, 5000);
      expect(state.remainingMs, 19000);
    });

    test('a 14s reset counts down from 14, not 24', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 14000),
        started('e2', 0),
      ], nowMs: 5000);
      expect(state.remainingMs, 9000);
    });

    test(
      'resetting while running immediately continues running at the new duration',
      () {
        final state = ShotClockEngine.replay(_rule, [
          reset('e1', 0, 24000),
          started('e2', 0),
          reset('e3', 10000, 14000), // reset mid-possession, clock was live.
        ], nowMs: 12000);
        expect(state.status, TimerStatus.running);
        expect(state.elapsedMs, 2000); // 2s into the new 14s leg.
        expect(state.remainingMs, 12000);
      },
    );

    test('resetting while paused stays paused at the new duration', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
        paused('e3', 5000),
        reset('e4', 5000, 14000),
      ], nowMs: 999999);
      expect(state.status, TimerStatus.paused);
      expect(state.remainingMs, 14000);
      expect(state.elapsedMs, 0);
    });

    test(
      'clamps at 0 and reports completed once the duration is exhausted',
      () {
        final state = ShotClockEngine.replay(_rule, [
          reset('e1', 0, 24000),
          started('e2', 0),
        ], nowMs: 999999);
        expect(state.status, TimerStatus.completed);
        expect(state.remainingMs, 0);
        expect(state.elapsedMs, 24000);
        expect(ShotClockEngine.isUnfinalizedCompletion(state, false), isTrue);
        expect(ShotClockEngine.isUnfinalizedCompletion(state, true), isFalse);
      },
    );

    test('SHOT_CLOCK_COMPLETED freezes elapsed even if queried much later', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
        completed('e3', 24000),
      ], nowMs: 999999);
      expect(state.status, TimerStatus.completed);
      expect(state.remainingMs, 0);
      expect(ShotClockEngine.isUnfinalizedCompletion(state, true), isFalse);
    });

    test('a second SHOT_CLOCK_STARTED after a pause resumes, not restarts '
        '(there is no separate RESUMED event in this engine)', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
        paused('e3', 10000),
        started('e4', 15000), // resumes, does not reset elapsed to 0.
      ], nowMs: 20000);
      expect(state.status, TimerStatus.running);
      // 10s before pause + 5s after resume = 15s elapsed, not 5s.
      expect(state.elapsedMs, 15000);
    });

    test('pause freezes elapsed regardless of the real-world gap', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
        paused('e3', 6000),
      ], nowMs: 999999);
      expect(state.status, TimerStatus.paused);
      expect(state.remainingMs, 18000);
    });

    test('undoing a reset reopens the previous leg', () {
      final events = [
        reset('e1', 0, 24000),
        started('e2', 0),
        paused('e3', 10000),
        reset('e4', 10000, 14000), // reset to 14s.
        undo('e5', 10000, targetEventId: 'e4'),
      ];
      final state = ShotClockEngine.replay(_rule, events, nowMs: 10000);
      // Back to the 24s leg, still paused at 10s elapsed.
      expect(state.status, TimerStatus.paused);
      expect(state.remainingMs, 14000); // 24000 - 10000.
    });

    test('replay is deterministic', () {
      final events = [reset('e1', 0, 24000), started('e2', 0)];
      final s1 = ShotClockEngine.replay(_rule, events, nowMs: 5000);
      final s2 = ShotClockEngine.replay(_rule, events, nowMs: 5000);
      expect(s1, s2);
    });

    test(
      'projectLiveElapsed reports RUNNING (not paused) while projecting',
      () {
        final baseline = ShotClockEngine.replay(_rule, [
          reset('e1', 0, 24000),
          started('e2', 0),
        ], nowMs: 0);
        final projected = ShotClockEngine.projectLiveElapsed(baseline, 5000);
        expect(projected.status, TimerStatus.running);
        expect(projected.elapsedMs, 5000);
        expect(projected.remainingMs, 19000);
      },
    );

    test(
      'projectLiveElapsed clamps at the current legs own duration (14s leg)',
      () {
        final baseline = ShotClockEngine.replay(_rule, [
          reset('e1', 0, 14000),
          started('e2', 0),
        ], nowMs: 0);
        final projected = ShotClockEngine.projectLiveElapsed(baseline, 20000);
        expect(projected.status, TimerStatus.completed);
        expect(projected.elapsedMs, 14000);
        expect(projected.remainingMs, 0);
      },
    );

    test('a duplicate event id is applied only once', () {
      final state = ShotClockEngine.replay(_rule, [
        reset('e1', 0, 24000),
        started('e2', 0),
        started('e2', 5000), // duplicate id, ignored.
      ], nowMs: 10000);
      expect(
        state.elapsedMs,
        10000,
      ); // measured from atMs=0, not re-started at 5000.
    });
  });
}
