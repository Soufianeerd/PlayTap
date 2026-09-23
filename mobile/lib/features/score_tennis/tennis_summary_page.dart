import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/racket_rule.dart';
import '../../l10n/app_localizations.dart';
import 'tennis_session_controller.dart';
import 'tennis_set_line.dart';

class TennisSummaryPage extends ConsumerStatefulWidget {
  const TennisSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TennisSummaryPage> createState() => _TennisSummaryPageState();
}

class _TennisSummaryPageState extends ConsumerState<TennisSummaryPage> {
  bool _undoing = false;

  /// Undoes the point that just won the match — same reopen-from-summary
  /// pattern as `PetanqueSummaryPage._undoLastRound`, adapted to Racket
  /// Core's `matchState`/`isUndoAvailable`.
  Future<void> _undoLastPoint() async {
    if (_undoing) return;
    setState(() => _undoing = true);

    final notifier = ref.read(
      tennisSessionControllerProvider(widget.sessionId).notifier,
    );
    await notifier.undoLast();

    if (!mounted) return;
    final reloaded = ref
        .read(tennisSessionControllerProvider(widget.sessionId))
        .value;
    if (reloaded != null && !reloaded.matchState.matchComplete) {
      context.pushReplacement('/score/tennis/session/${widget.sessionId}');
      return;
    }
    setState(() => _undoing = false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncView = ref.watch(
      tennisSessionControllerProvider(widget.sessionId),
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
          final state = view.matchState;
          final winnerId = state.winner;
          final rule = view.racketRule;

          return Padding(
            padding: const EdgeInsets.all(PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.presetTennis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: PlayTapSpacing.sm),
                if (winnerId != null)
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
                          '${state.setsWon[side.id] ?? 0}',
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
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  state.completedSets
                      .map((s) => tennisSetLine(l10n, s))
                      .join(', '),
                  style: PlayTapTypography.body.copyWith(color: colors.muted),
                ),
                const SizedBox(height: PlayTapSpacing.sm),
                Text(
                  l10n.tennisFormatBestOf3,
                  style: PlayTapTypography.caption.copyWith(
                    color: colors.muted,
                  ),
                ),
                Text(
                  rule.gameScoring.advantageMode == AdvantageMode.advantage
                      ? l10n.tennisScoringAdvantage
                      : l10n.tennisScoringNoAd,
                  style: PlayTapTypography.caption.copyWith(
                    color: colors.muted,
                  ),
                ),
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
                    onPressed: _undoing ? null : _undoLastPoint,
                    child: _undoing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.tennisUndoLastPoint),
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
