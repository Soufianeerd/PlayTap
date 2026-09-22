import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/timer_mode_label.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/timer_mode.dart';
import '../../l10n/app_localizations.dart';
import 'timer_session_controller.dart';

class TimerSummaryPage extends ConsumerWidget {
  const TimerSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshot = ref.watch(timerSessionControllerProvider(sessionId));
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: asyncSnapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(l10n.errorPrefix(e.toString()))),
        data: (snapshot) {
          final duration = snapshot.endedAt != null
              ? snapshot.endedAt!.difference(snapshot.startedAt)
              : Duration.zero;

          return Padding(
            padding: const EdgeInsets.all(PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timerModeLabel(l10n, snapshot.spec.mode),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: PlayTapSpacing.xxl),
                Text(
                  _formatDuration(snapshot.state.elapsedMs),
                  style: PlayTapTypography.scoreDisplay.copyWith(
                    fontSize: 56,
                    color: colors.primary,
                  ),
                ),
                if (snapshot.spec.mode == TimerMode.lapTimer) ...[
                  const SizedBox(height: PlayTapSpacing.sm),
                  Text(
                    l10n.lapsCountPlural(snapshot.state.laps.length),
                    style: PlayTapTypography.body.copyWith(color: colors.muted),
                  ),
                ],
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  duration.inMinutes < 1
                      ? l10n.lessThanAMinute
                      : l10n.minutesShort(duration.inMinutes),
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

String _formatDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
