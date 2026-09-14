import 'timer_mode.dart';

/// Engine-facing timer configuration — see `playtap-timer-engine`.
class TimerSpec {
  const TimerSpec({
    required this.schemaVersion,
    required this.mode,
    this.durationTargetMs,
  }) : assert(
         mode != TimerMode.countdown || durationTargetMs != null,
         'COUNTDOWN requires durationTargetMs',
       );

  final int schemaVersion;
  final TimerMode mode;

  /// Required for COUNTDOWN, must be > 0 (see section 19 — validated at
  /// config time, not just here). Unused for STOPWATCH/LAP_TIMER.
  final int? durationTargetMs;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mode': mode.toJson(),
    if (durationTargetMs != null) 'durationTargetMs': durationTargetMs,
  };

  factory TimerSpec.fromJson(Map<String, dynamic> json) => TimerSpec(
    schemaVersion: json['schemaVersion'] as int,
    mode: TimerMode.fromJson(json['mode'] as String),
    durationTargetMs: json['durationTargetMs'] as int?,
  );
}
