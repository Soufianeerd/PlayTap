import '../models/match_rule.dart';

/// Whether a Football/Football-family match allows a draw or must be
/// resolved (overtime + shootout) — a competition-level choice, not a law
/// (IFAB Law 7/10: extra time and shootout format are competition rules,
/// not mandated for every match — see docs/SPORT_RULES.md). Basketball has
/// no such toggle: FIBA never allows a draw, so `basketball_rulesets.dart`
/// never exposes this.
enum TeamMatchFormat {
  league,
  knockout;

  /// Reconstructs the format from what's actually persisted in a
  /// [MatchRule] — never from transient config-screen state (mirrors
  /// `PetanqueFormat.fromPersisted`'s identical warning). A match is
  /// `knockout` if it cannot end in a draw; `league` otherwise.
  static TeamMatchFormat fromPersisted(MatchRule rule) =>
      rule.matchEnd.drawAllowed
      ? TeamMatchFormat.league
      : TeamMatchFormat.knockout;
}
