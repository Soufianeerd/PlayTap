/// Basketball shot-clock configuration — FIBA Official Basketball Rules,
/// Article 29 (see docs/SPORT_RULES.md). Absent (`null` on
/// `MatchRule.shotClockRule`) means the sport has no shot clock (Football,
/// Futsal — FIFA Futsal Laws have no shot-clock equivalent).
///
/// PlayTap never infers *why* a reset happens (offensive rebound, loose-
/// ball foul, throw-in rule) — it only offers the two durations FIBA
/// defines and lets the scorer/referee decide which applies, exactly like
/// a physical scorer's table shot-clock unit. See `ShotClockEngine`.
class ShotClockRule {
  const ShotClockRule({
    required this.schemaVersion,
    required this.defaultDurationMs,
    required this.shortResetDurationMs,
  });

  final int schemaVersion;

  /// Standard duration a reset restarts at (24000ms — FIBA).
  final int defaultDurationMs;

  /// The "short reset" duration (14000ms — FIBA: offensive rebound of a
  /// missed shot that touched the rim, a defensive loose-ball foul right
  /// after such a miss, or the offense retaining the ball out of bounds
  /// right after such a miss).
  final int shortResetDurationMs;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'defaultDurationMs': defaultDurationMs,
    'shortResetDurationMs': shortResetDurationMs,
  };

  factory ShotClockRule.fromJson(Map<String, dynamic> json) => ShotClockRule(
    schemaVersion: json['schemaVersion'] as int,
    defaultDurationMs: json['defaultDurationMs'] as int,
    shortResetDurationMs: json['shortResetDurationMs'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is ShotClockRule &&
      defaultDurationMs == other.defaultDurationMs &&
      shortResetDurationMs == other.shortResetDurationMs;

  @override
  int get hashCode => Object.hash(defaultDurationMs, shortResetDurationMs);
}
