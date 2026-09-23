import '../../domain/models/racket_state.dart';
import '../../l10n/app_localizations.dart';
import 'tennis_actions.dart';

/// One completed set formatted for display — shared between the Summary
/// screen and History so a set never reads differently in the two places
/// (e.g. "7-6 (7-5)" for a tie-break set, "Match Tie-Break 10-8" for a
/// Match Tie-break deciding set — see `RacketSetResult.isMatchTieBreak`).
String tennisSetLine(AppLocalizations l10n, RacketSetResult set) {
  final gamesA = set.games[sideATennisId] ?? 0;
  final gamesB = set.games[sideBTennisId] ?? 0;
  final tb = set.tieBreakScore;
  if (set.isMatchTieBreak) {
    return '${l10n.tennisMatchTieBreakShort} ${tb![sideATennisId]}-${tb[sideBTennisId]}';
  }
  final base = '$gamesA-$gamesB';
  if (tb == null) return base;
  return '$base (${tb[sideATennisId]}-${tb[sideBTennisId]})';
}
