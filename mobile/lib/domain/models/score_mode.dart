/// Base scoring shapes from `playtap-score-engine`. Only [freeScore] is
/// implemented (Phase 1B.1) — the others exist so `ScoreRule` can grow into
/// them later without renaming this enum.
enum ScoreMode {
  freeScore,
  targetScore,
  sequentialScore,
  teamScore;

  String toJson() => switch (this) {
    ScoreMode.freeScore => 'FREE_SCORE',
    ScoreMode.targetScore => 'TARGET_SCORE',
    ScoreMode.sequentialScore => 'SEQUENTIAL_SCORE',
    ScoreMode.teamScore => 'TEAM_SCORE',
  };

  static ScoreMode fromJson(String value) => switch (value) {
    'FREE_SCORE' => ScoreMode.freeScore,
    'TARGET_SCORE' => ScoreMode.targetScore,
    'SEQUENTIAL_SCORE' => ScoreMode.sequentialScore,
    'TEAM_SCORE' => ScoreMode.teamScore,
    _ => throw ArgumentError.value(value, 'value', 'Unknown ScoreMode'),
  };
}
