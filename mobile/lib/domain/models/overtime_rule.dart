/// Overtime configuration — see `MatchRule` composition
/// (docs/DATA_MODEL.md) and `MatchEngine.decideNextPhase`, the only place
/// this is interpreted. Absent (`null` on `MatchRule.overtime`) means the
/// sport never plays overtime (e.g. a league football match that allows a
/// draw).
///
/// [maxCount] carries two distinct, purely data-driven semantics — no
/// sport identity is ever checked to pick between them:
/// - **null ("uncapped")**: overtime is a single period, decisive on its
///   own — the match ends the moment it isn't level, and another period
///   is played only if it's still level (Basketball, FIBA Article 8: "as
///   many 5-minute overtimes as necessary" — never a draw).
/// - **finite N ("fixed-length block")**: exactly N overtime periods are
///   always played out in full before any decision is made, regardless of
///   the score partway through (Football extra time, commonly 2×15 —
///   IFAB leaves the exact format to the competition). Only once all N
///   periods are done does the match check level-ness and fall through to
///   a shootout or a draw per `MatchEndRule`.
class OvertimeRule {
  const OvertimeRule({required this.durationMs, this.maxCount});

  final int durationMs;

  /// Null = unlimited (Basketball). A finite value caps how many overtime
  /// periods are played before falling through to shootout/draw.
  final int? maxCount;

  Map<String, dynamic> toJson() => {
    'durationMs': durationMs,
    if (maxCount != null) 'maxCount': maxCount,
  };

  factory OvertimeRule.fromJson(Map<String, dynamic> json) => OvertimeRule(
    durationMs: json['durationMs'] as int,
    maxCount: json['maxCount'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is OvertimeRule &&
      durationMs == other.durationMs &&
      maxCount == other.maxCount;

  @override
  int get hashCode => Object.hash(durationMs, maxCount);
}
