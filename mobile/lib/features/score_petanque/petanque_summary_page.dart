import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import 'petanque_session_controller.dart';

class PetanqueSummaryPage extends ConsumerStatefulWidget {
  const PetanqueSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<PetanqueSummaryPage> createState() =>
      _PetanqueSummaryPageState();
}

class _PetanqueSummaryPageState extends ConsumerState<PetanqueSummaryPage> {
  bool _undoing = false;

  /// Undoes the mène that just won the match — the engine/controller
  /// already know how to reopen it (`ScoreEngine._replayPointBased`,
  /// `PetanqueSessionController.undoLast`); this only wires that existing
  /// capability up to the Summary screen, where it was previously
  /// unreachable (see the review, 2026-09-22). No score logic duplicated
  /// here: the post-undo state is read straight back from the controller.
  Future<void> _undoLastRound() async {
    if (_undoing) return;
    setState(() => _undoing = true);

    final notifier = ref.read(
      petanqueSessionControllerProvider(widget.sessionId).notifier,
    );
    await notifier.undoLast();

    if (!mounted) return;
    final reloaded = ref
        .read(petanqueSessionControllerProvider(widget.sessionId))
        .value;
    if (reloaded != null && !reloaded.scoreState.matchComplete) {
      context.pushReplacement('/score/petanque/session/${widget.sessionId}');
      return;
    }
    // Nothing eligible to undo (shouldn't happen from a completed match's
    // Summary, but never leave the button silently stuck): just re-enable.
    setState(() => _undoing = false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncView = ref.watch(
      petanqueSessionControllerProvider(widget.sessionId),
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
          final winnerId = view.scoreState.winner;

          return Padding(
            padding: const EdgeInsets.all(PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.presetPetanque,
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
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  l10n.endsCountPlural(view.scoreState.rounds.length),
                  style: PlayTapTypography.body.copyWith(color: colors.muted),
                ),
                Text(
                  minutes < 1
                      ? l10n.lessThanAMinute
                      : l10n.minutesShort(minutes),
                  style: PlayTapTypography.body.copyWith(color: colors.muted),
                ),
                const Spacer(),
                // Secondary action: reopens the match by undoing the mène
                // that just won it. Deliberately an OutlinedButton, visually
                // subordinate to the primary "view history" action below —
                // see the review UX note, 2026-09-22.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _undoing ? null : _undoLastRound,
                    child: _undoing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.undoLastRound),
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
