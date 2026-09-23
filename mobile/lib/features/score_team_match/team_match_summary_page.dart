import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/match_state.dart';
import '../../l10n/app_localizations.dart';
import 'team_match_labels.dart';
import 'team_match_session_controller.dart';

/// Shared summary page for Basketball/Football/Futsal — final score, the
/// shootout line when one was played (kept visually and numerically
/// separate from the match score it never merges into — see
/// `ShootoutEngine`'s composition note), and undo-from-summary (mirrors
/// the Pétanque fix in commit `9e7085e`: undoing the event that completed
/// the match reopens it).
class TeamMatchSummaryPage extends ConsumerStatefulWidget {
  const TeamMatchSummaryPage({
    super.key,
    required this.sessionId,
    required this.sessionRoute,
  });

  final String sessionId;

  /// Where to navigate back to if undo reopens the match — the shared
  /// active-session route for whichever sport this is.
  final String sessionRoute;

  @override
  ConsumerState<TeamMatchSummaryPage> createState() =>
      _TeamMatchSummaryPageState();
}

class _TeamMatchSummaryPageState extends ConsumerState<TeamMatchSummaryPage> {
  bool _undoing = false;

  Future<void> _undoLast() async {
    if (_undoing) return;
    setState(() => _undoing = true);

    final notifier = ref.read(
      teamMatchSessionControllerProvider(widget.sessionId).notifier,
    );
    await notifier.undoLast();

    if (!mounted) return;
    final reloaded = ref
        .read(teamMatchSessionControllerProvider(widget.sessionId))
        .value;
    if (reloaded != null && !reloaded.matchState.matchEnded) {
      context.pushReplacement(widget.sessionRoute);
      return;
    }
    setState(() => _undoing = false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncView = ref.watch(
      teamMatchSessionControllerProvider(widget.sessionId),
    );
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(l10n.errorPrefix(e.toString()))),
        data: (view) {
          final duration = view.endedAt != null
              ? view.endedAt!.difference(view.startedAt)
              : Duration.zero;
          final minutes = duration.inMinutes;
          final scores = view.scoreState.scores;
          // Derived from the engine's own recorded reason, never
          // re-computed from raw scores — `MatchEngine.decideNextPhase`
          // already made this exact determination once, authoritatively;
          // re-deriving it here from `scores` risks disagreeing with it
          // (e.g. a shootout winner isn't the side with the higher match
          // score — the match score can be level even when the shootout
          // decided it).
          final endReason = view.matchState.endReason;
          final isDraw = endReason == MatchEndReason.regulationDraw;
          final winnerId = switch (endReason) {
            MatchEndReason.decidedByShootout => view.shootoutState?.winner,
            MatchEndReason.decidedInRegulation ||
            MatchEndReason.decidedInOvertime =>
              scores.entries.reduce((a, b) => a.value > b.value ? a : b).key,
            MatchEndReason.regulationDraw || null => null,
          };

          return Padding(
            padding: const EdgeInsets.all(PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamMatchSportLabel(l10n, view.matchRule.rulesetId),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: PlayTapSpacing.sm),
                if (isDraw)
                  Text(
                    l10n.matchDrawResultLabel,
                    style: PlayTapTypography.body.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (winnerId != null)
                  Text(
                    l10n.winnerAnnouncement(
                      view.sides.firstWhere((s) => s.id == winnerId).name,
                    ),
                    style: PlayTapTypography.body.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: PlayTapSpacing.xxl),
                for (final side in view.sides)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: PlayTapSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          side.name,
                          style: PlayTapTypography.headline.copyWith(
                            color: colors.foreground,
                            fontSize: 20,
                            fontWeight: side.id == winnerId
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${scores[side.id] ?? 0}',
                          style: PlayTapTypography.scoreDisplay.copyWith(
                            fontSize: 36,
                            color: side.id == winnerId
                                ? colors.primary
                                : colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (view.shootoutState != null) ...[
                  const SizedBox(height: PlayTapSpacing.sm),
                  Text(
                    l10n.shootoutScoreLine(
                      view.shootoutState!.scores[view.sides[0].id] ?? 0,
                      view.shootoutState!.scores[view.sides[1].id] ?? 0,
                    ),
                    style: PlayTapTypography.body.copyWith(color: colors.muted),
                  ),
                ],
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  minutes < 1
                      ? l10n.lessThanAMinute
                      : l10n.minutesShort(minutes),
                  style: PlayTapTypography.body.copyWith(color: colors.muted),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _undoing ? null : _undoLast,
                    child: _undoing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.undoLastActionLabel),
                  ),
                ),
                const SizedBox(height: PlayTapSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/history'),
                    child: Text(l10n.viewHistoryButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
