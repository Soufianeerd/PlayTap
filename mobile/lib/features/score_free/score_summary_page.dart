import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import 'free_score_session_controller.dart';

class ScoreSummaryPage extends ConsumerWidget {
  const ScoreSummaryPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncView = ref.watch(freeScoreSessionControllerProvider(sessionId));
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Résumé')),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (view) {
          final duration = view.endedAt != null
              ? view.endedAt!.difference(view.startedAt)
              : Duration.zero;
          final minutes = duration.inMinutes;

          return Padding(
            padding: const EdgeInsets.all(PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score libre',
                  style: Theme.of(context).textTheme.headlineMedium,
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
                          style: PlayTapTypography.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${view.scoreState.scores[side.id] ?? 0}',
                          style: PlayTapTypography.title.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: PlayTapSpacing.lg),
                Text(
                  minutes < 1 ? 'Moins d\'une minute' : '$minutes min',
                  style: PlayTapTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/history'),
                    child: const Text('VOIR L\'HISTORIQUE'),
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
