import '../../domain/models/match_rule.dart';
import '../../domain/models/match_state.dart';
import '../../l10n/app_localizations.dart';

/// UI-only display helpers — never consulted by any engine. "Which sport
/// is this" and "what do we call this period" are presentation concerns,
/// the same way `ScoringSide.name` is presentation while the engine only
/// ever sees an abstract side id (see `playtap-score-engine`). Deriving
/// these from [MatchRule.rulesetId]/`periods.length` here, rather than
/// threading a `Sport` enum through the domain layer, keeps the generic
/// architecture rule intact: no engine file ever branches on sport
/// identity — only this display layer does, and only for labels.
String teamMatchSportLabel(AppLocalizations l10n, String rulesetId) {
  if (rulesetId.startsWith('basketball.')) return l10n.presetBasketball;
  if (rulesetId.startsWith('football.')) return l10n.presetFootball;
  if (rulesetId.startsWith('futsal.')) return l10n.presetFutsal;
  return rulesetId; // defensive: should never happen for a rule this app created.
}

String teamMatchPeriodLabel(
  AppLocalizations l10n,
  MatchRule rule,
  MatchState state,
) {
  if (state.isOvertimePeriod) return l10n.overtimeLabel(state.overtimeCount);
  if (rule.periods.length == 4) {
    return l10n.periodLabelQuarter(state.periodIndex + 1);
  }
  if (rule.periods.length == 2) {
    return state.periodIndex == 0
        ? l10n.periodLabelFirstHalf
        : l10n.periodLabelSecondHalf;
  }
  return l10n.periodLabelQuarter(state.periodIndex + 1); // defensive fallback.
}

/// `mm:ss` — never centiseconds (this is a match clock, not a stopwatch);
/// never negative (mirrors `TimerState.remainingMs`'s own clamping).
String formatMatchClockMs(int ms) {
  final clamped = ms < 0 ? 0 : ms;
  final totalSeconds = clamped ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
