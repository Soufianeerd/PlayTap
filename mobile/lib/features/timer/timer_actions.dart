import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/origin_device.dart';
import '../../domain/models/session_category.dart';
import '../../domain/models/timer_spec.dart';

const _uuid = Uuid();

String presetRefFor(TimerSpec spec) => switch (spec.mode.toJson()) {
  'STOPWATCH' => 'stopwatch',
  'COUNTDOWN' => 'countdown',
  'LAP_TIMER' => 'lap_timer',
  _ => throw UnimplementedError('No preset for ${spec.mode}'),
};

/// Creates a new Timer session and its `SESSION_STARTED` + `TIMER_STARTED`
/// events atomically, then returns the new session id. Two events, not
/// one, mirroring Score Libre's split between session metadata
/// (`SESSION_STARTED`, carries the config) and the first event the pure
/// engine actually cares about (`TIMER_STARTED`, starts the clock) — see
/// `domain/engines/timer_engine.dart`.
Future<String> startTimerSession(WidgetRef ref, TimerSpec spec) async {
  final sessionId = _uuid.v4();
  final now = ref.read(clockProvider).now();

  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await ref
        .read(sessionRepositoryProvider)
        .createSession(
          id: sessionId,
          category: SessionCategory.timer,
          ownerDevice: OriginDevice.phone,
          presetRef: presetRefFor(spec),
          startedAt: now,
        );
    final eventRepo = ref.read(eventRepositoryProvider);
    await eventRepo.appendPhoneEvent(
      id: _uuid.v4(),
      sessionId: sessionId,
      type: SessionEventType.sessionStarted,
      payload: {'timerSpec': spec.toJson()},
      timestamp: now,
    );
    await eventRepo.appendPhoneEvent(
      id: _uuid.v4(),
      sessionId: sessionId,
      type: SessionEventType.timerStarted,
      payload: const {},
      timestamp: now,
    );
  });

  return sessionId;
}
