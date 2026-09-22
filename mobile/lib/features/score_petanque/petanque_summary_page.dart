import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import 'petanque_session_controller.dart';

class PetanqueSummaryPage extends ConsumerWidget {
  const PetanqueSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncView = ref.watch(petanqueSessionControllerProvider(sessionId));
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
