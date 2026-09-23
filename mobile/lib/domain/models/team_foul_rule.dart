/// Team-foul counter configuration — **one generic abstraction reused by
/// both Basketball's "bonus" (FIBA Article 41) and Futsal's accumulated-
/// foul DFKSAF mechanism (FIFA Futsal Law 12/13)**, not two separate rule
/// types: both are, at the data level, "the Nth team foul in the current
/// counting bracket crosses a threshold," and both share the *same*
/// bracket/reset behavior verified officially for this phase (see
/// docs/SPORT_RULES.md) — the count resets to zero at the start of every
/// **regulation** period, and does **not** reset entering overtime (it
/// continues from wherever the last regulation period left off: FIBA
/// "all team fouls committed in each overtime shall be considered as
/// being committed in the fourth quarter"; FIFA's futsal glossary:
/// accumulated fouls from the second period carry into extra time).
/// Because this reset/carry behavior is confirmed identical for every
/// sport in this phase, it lives in `TeamFoulEngine` itself, not as a
/// configurable field here — only the threshold differs.
///
/// Absent (`null` on `MatchRule.teamFoulRule`) means the sport doesn't
/// track team fouls (Football, in this phase).
///
/// PlayTap never infers whether a foul is a shooting foul, a loose-ball
/// foul, a penalty-kick foul, or anything else — the scorer/referee taps
/// "add team foul" for whatever they judge countable, exactly the
/// generic "PlayTap informe et compte" scope from `docs/SPORT_RULES.md`.
class TeamFoulRule {
  const TeamFoulRule({
    required this.schemaVersion,
    required this.bonusThreshold,
  });

  final int schemaVersion;

  /// The foul count at which the team enters the penalty/bonus situation
  /// (5 — Basketball) or DFKSAF applies (6 — Futsal) — the (bonusThreshold
  /// - 1)th foul is still "not yet," this one and every one after it is.
  final int bonusThreshold;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'bonusThreshold': bonusThreshold,
  };

  factory TeamFoulRule.fromJson(Map<String, dynamic> json) => TeamFoulRule(
    schemaVersion: json['schemaVersion'] as int,
    bonusThreshold: json['bonusThreshold'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is TeamFoulRule && bonusThreshold == other.bonusThreshold;

  @override
  int get hashCode => bonusThreshold.hashCode;
}
