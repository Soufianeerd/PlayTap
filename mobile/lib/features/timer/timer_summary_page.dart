import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/timer_mode.dart';
import 'timer_session_controller.dart';

class TimerSummaryPage extends ConsumerWidget {
  const TimerSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshot = ref.watch(timerSessionControllerProvider(sessionId));
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Résumé')),
      body: asyncSnapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
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
                  _titleFor(snapshot.spec.mode),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: PlayTapSpacing.xxl),
                Text(
                  _formatDuration(snapshot.state.elapsedMs),
                  style: PlayTapTypography.title.copyWith(color: colors.accent),
                ),
                if (snapshot.spec.mode == TimerMode.lapTimer) ...[
                  const SizedBox(height: PlayTapSpacing.sm),
                  Text(
                    '${snapshot.state.laps.length} lap${snapshot.state.laps.length == 1 ? '' : 's'}',
                    style: PlayTapTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  duration.inMinutes < 1
                      ? 'Moins d\'une minute'
                      : '${duration.inMinutes} min',
                  style: PlayTapTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/history'),
                    child: const Text('TERMINER'),
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

String _titleFor(TimerMode mode) => switch (mode) {
  TimerMode.stopwatch => 'Chronomètre',
  TimerMode.countdown => 'Countdown',
  TimerMode.lapTimer => 'Lap Timer',
  TimerMode.interval => 'Timer',
};

String _formatDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
