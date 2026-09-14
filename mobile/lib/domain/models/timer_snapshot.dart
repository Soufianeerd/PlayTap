import 'session_status.dart';
import 'timer_spec.dart';
import 'timer_state.dart';

/// A fully-resolved Timer session — spec + derived engine state, ready for
/// the UI (see `domain/engines/timer_deriver.dart`). [sessionStatus] is the
/// session's own lifecycle column (ACTIVE/COMPLETED/ABANDONED) and can
/// briefly disagree with `state.status` (engine-level RUNNING/PAUSED/
/// COMPLETED): a COUNTDOWN can be engine-`completed` for an instant before
/// the controller persists the finalizing event and the session lifecycle
/// catches up — see `TimerSessionController._finalizeIfExpired`.
class TimerSnapshot {
  const TimerSnapshot({
    required this.spec,
    required this.state,
    required this.sessionStatus,
    required this.startedAt,
    required this.endedAt,
  });

  final TimerSpec spec;
  final TimerState state;
  final SessionStatus sessionStatus;
  final DateTime startedAt;
  final DateTime? endedAt;
}
