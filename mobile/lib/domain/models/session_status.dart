/// See docs/DATA_MODEL.md — Session lifecycle status. `paused` is reserved
/// for the Timer Engine (Phase 1B+); Score Libre never produces it.
enum SessionStatus {
  active,
  paused,
  completed,
  abandoned;

  String toJson() => name.toUpperCase();

  static SessionStatus fromJson(String value) =>
      SessionStatus.values.firstWhere((s) => s.name.toUpperCase() == value);
}
