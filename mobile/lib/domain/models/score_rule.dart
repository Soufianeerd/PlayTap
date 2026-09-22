import 'score_mode.dart';
import 'score_target.dart';

/// Engine-facing scoring configuration — see `playtap-score-engine`. The
/// engine only knows abstract side ids here, never display names (those
/// live on `ScoringSide`, a config/presentation concern).
///
/// Sealed so `ScoreEngine.replay` can exhaustively switch on the mode; new
/// modes (SEQUENTIAL_SCORE, ...) are added as new subtypes without touching
/// this file's existing cases.
///
/// ## Architecture note — composing TARGET_SCORE and TEAM_SCORE
///
/// TARGET_SCORE ("first to N wins") and TEAM_SCORE ("scoring with
/// configurable increments") are not mutually-exclusive top-level modes:
/// Pétanque needs both at once (target 13, 1-6 points per round). Rather
/// than adding a third sealed subtype for every mode combination a future
/// sport needs, the "how a match ends" concern is factored out into a
/// standalone, reusable value object ([ScoreTarget], see
/// `score_target.dart`). [TargetScoreRule] always carries one;
/// [TeamScoreRule] carries an *optional* one — present composes TEAM_SCORE
/// with a target win condition (Pétanque); absent gives plain
/// manually-ended team scoring (Basketball/Football V2). This keeps each
/// concrete `ScoreRule` exhaustively switchable in `ScoreEngine.replay`
/// while letting the "win condition" facet be shared and reused instead of
/// duplicated per mode. See docs/DATA_MODEL.md for the persisted shape.
sealed class ScoreRule {
  const ScoreRule({required this.schemaVersion, required this.mode});

  final int schemaVersion;
  final ScoreMode mode;

  Map<String, dynamic> toJson();

  factory ScoreRule.fromJson(Map<String, dynamic> json) {
    final mode = ScoreMode.fromJson(json['mode'] as String);
    return switch (mode) {
      ScoreMode.freeScore => FreeScoreRule.fromJson(json),
      ScoreMode.targetScore => TargetScoreRule.fromJson(json),
      ScoreMode.teamScore => TeamScoreRule.fromJson(json),
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

/// TARGET_SCORE: first side to reach [target.targetScore] wins — a single
/// point per `POINT_SCORED` event (`amount` defaults to 1 when omitted, and
/// is rejected if present and not 1: this mode never varies its increment,
/// see [TeamScoreRule] for that). Table tennis (11), badminton (21) — see
/// `playtap-sports-rules`.
class TargetScoreRule extends ScoreRule {
  const TargetScoreRule({
    required super.schemaVersion,
    required this.sideIds,
    required this.target,
  }) : super(mode: ScoreMode.targetScore);

  final List<String> sideIds;
  final ScoreTarget target;

  @override
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mode': mode.toJson(),
    'sides': sideIds,
    ...target.toJson(),
  };

  factory TargetScoreRule.fromJson(Map<String, dynamic> json) =>
      TargetScoreRule(
        schemaVersion: json['schemaVersion'] as int,
        sideIds: (json['sides'] as List).cast<String>(),
        target: ScoreTarget.fromJson(json),
      );
}

/// TEAM_SCORE: scoring with a configurable set of allowed per-event
/// increments (e.g. Basketball {1,2,3}, Football {1}, Pétanque {1..6}).
/// [target] is optional and composes a TARGET_SCORE-style win condition on
/// top (see the architecture note on [ScoreRule]) — present for Pétanque
/// (target 13), absent for sports that only end manually (Basketball/
/// Football V2, not implemented yet).
class TeamScoreRule extends ScoreRule {
  const TeamScoreRule({
    required super.schemaVersion,
    required this.sideIds,
    required this.allowedIncrements,
    this.target,
  }) : super(mode: ScoreMode.teamScore);

  final List<String> sideIds;

  /// Every value a single `POINT_SCORED` event's `amount` may legally take;
  /// any other amount is ignored (see `ScoreEngine`). Never empty.
  final List<int> allowedIncrements;

  final ScoreTarget? target;

  @override
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mode': mode.toJson(),
    'sides': sideIds,
    'allowedIncrements': allowedIncrements,
    if (target != null) 'target': target!.toJson(),
  };

  factory TeamScoreRule.fromJson(Map<String, dynamic> json) => TeamScoreRule(
    schemaVersion: json['schemaVersion'] as int,
    sideIds: (json['sides'] as List).cast<String>(),
    allowedIncrements: (json['allowedIncrements'] as List).cast<int>(),
    target: json['target'] != null
        ? ScoreTarget.fromJson((json['target'] as Map).cast<String, dynamic>())
        : null,
  );
}
