/// Shared "how a match ends" component — see `playtap-score-engine` and
/// docs/DATA_MODEL.md ("ScoreRule composition"). Deliberately a plain value
/// object, not a `ScoreRule` subtype: it is *embedded* by rules that need a
/// target-based win condition ([TargetScoreRule] always, [TeamScoreRule]
/// optionally) instead of being a mutually-exclusive top-level mode. This is
/// what lets TARGET_SCORE and TEAM_SCORE compose for Pétanque (target 13 +
/// variable per-round increments) without a new sealed subtype per
/// combination — see architecture note in `score_rule.dart`.
class ScoreTarget {
  const ScoreTarget({
    required this.targetScore,
    this.automaticCompletion = true,
    this.winBy,
  });

  final int targetScore;

  /// When true, the match completes itself the moment a side's score
  /// crosses [targetScore] (subject to [winBy] if set) — no explicit
  /// `SESSION_COMPLETED` event needed. When false, reaching the target is
  /// tracked but the match only ends via an explicit completion event
  /// (mirrors FREE_SCORE's manual end).
  final bool automaticCompletion;

  /// Optional win-by-margin clause (e.g. table tennis 11, win by 2): when
  /// present and enabled, reaching [targetScore] alone isn't sufficient —
  /// the leader's margin over every other side must also reach
  /// [ScoreWinBy.margin].
  final ScoreWinBy? winBy;

  Map<String, dynamic> toJson() => {
    'targetScore': targetScore,
    'automaticCompletion': automaticCompletion,
    if (winBy != null) 'winBy': winBy!.toJson(),
  };

  factory ScoreTarget.fromJson(Map<String, dynamic> json) => ScoreTarget(
    targetScore: json['targetScore'] as int,
    automaticCompletion: json['automaticCompletion'] as bool? ?? true,
    winBy: json['winBy'] != null
        ? ScoreWinBy.fromJson((json['winBy'] as Map).cast<String, dynamic>())
        : null,
  );

  @override
  bool operator ==(Object other) =>
      other is ScoreTarget &&
      targetScore == other.targetScore &&
      automaticCompletion == other.automaticCompletion &&
      winBy == other.winBy;

  @override
  int get hashCode => Object.hash(targetScore, automaticCompletion, winBy);
}

/// See [ScoreTarget.winBy].
class ScoreWinBy {
  const ScoreWinBy({required this.enabled, required this.margin});

  final bool enabled;
  final int margin;

  Map<String, dynamic> toJson() => {'enabled': enabled, 'margin': margin};

  factory ScoreWinBy.fromJson(Map<String, dynamic> json) => ScoreWinBy(
    enabled: json['enabled'] as bool,
    margin: json['margin'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is ScoreWinBy && enabled == other.enabled && margin == other.margin;

  @override
  int get hashCode => Object.hash(enabled, margin);
}
