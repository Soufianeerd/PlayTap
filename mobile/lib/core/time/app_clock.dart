/// Wall-clock time source, injectable for tests.
///
/// This is deliberately a thin placeholder: it is only used for things like
/// event timestamps in this scaffolding phase. The Timer/Interval Engine
/// (Phase 1B) must compute `elapsed`/`remaining` from a monotonic clock, not
/// this one — see the "Quelle horloge pour `now` ?" section of the
/// `playtap-timer-engine` skill.
abstract class AppClock {
  DateTime now();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}
