import 'score_mode.dart';

/// Engine-facing scoring configuration — see `playtap-score-engine`. The
/// engine only knows abstract side ids here, never display names (those
/// live on `ScoringSide`, a config/presentation concern).
///
/// Sealed so `ScoreEngine.replay` can exhaustively switch on the mode; new
/// modes (TARGET_SCORE, SEQUENTIAL_SCORE, TEAM_SCORE, ...) are added as new
/// subtypes without touching this file's existing cases.
sealed class ScoreRule {
  const ScoreRule({required this.schemaVersion, required this.mode});

  final int schemaVersion;
  final ScoreMode mode;

  Map<String, dynamic> toJson();

  factory ScoreRule.fromJson(Map<String, dynamic> json) {
    final mode = ScoreMode.fromJson(json['mode'] as String);
    return switch (mode) {
      ScoreMode.freeScore => FreeScoreRule.fromJson(json),
      _ => throw UnsupportedScoreModeException(mode),
    };
  }
}

/// Thrown when a `ScoreRule`/fixture names a mode this build doesn't
/// implement yet — used by the conformance runner to report "mode not
/// supported" explicitly instead of failing silently (see docs/CONFORMANCE.md
/// and the Phase 1B.1 scope: only FREE_SCORE is implemented).
class UnsupportedScoreModeException implements Exception {
  UnsupportedScoreModeException(this.mode);

  final ScoreMode mode;

  @override
  String toString() => 'UnsupportedScoreModeException: ${mode.toJson()}';
}

/// FREE_SCORE: a plain running counter per side, no target, no automatic
/// end — the user ends the session manually (see `playtap-score-engine`).
class FreeScoreRule extends ScoreRule {
  const FreeScoreRule({
    required super.schemaVersion,
    required this.sideIds,
    required this.defaultIncrement,
  }) : super(mode: ScoreMode.freeScore);

  /// Abstract side ids, e.g. `["side_a", "side_b"]`. 2 to 4 sides for
  /// Phase 1B.1 (see playtap-sports-rules generic "Score libre").
  final List<String> sideIds;

  /// V1 UI always sends 1; the field exists so +2/+3 (basketball-style)
  /// don't require a schema change later — never exposed in the UI yet.
  final int defaultIncrement;

  @override
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mode': mode.toJson(),
    'sides': sideIds,
    'defaultIncrement': defaultIncrement,
  };

  factory FreeScoreRule.fromJson(Map<String, dynamic> json) => FreeScoreRule(
    schemaVersion: json['schemaVersion'] as int,
    sideIds: (json['sides'] as List).cast<String>(),
    defaultIncrement: json['defaultIncrement'] as int,
  );
}
