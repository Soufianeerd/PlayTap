import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/engines/free_score_deriver.dart';
import '../../domain/models/free_score_snapshot.dart';
import '../../domain/models/session_category.dart';

/// Completed Score Libre sessions, most recent first — always derived from
/// Session + Events replay (see docs/DATA_MODEL.md, "HistoryEntry"). Never
/// a stored `finalScore` column, never fake/demo data.
final completedFreeScoreSessionsProvider = FutureProvider((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final sessions = await sessionRepo.getCompletedSessions(
    SessionCategory.score,
  );

  final snapshots = <FreeScoreSnapshot>[];
  for (final session in sessions) {
    final events = await eventRepo.getEventsForSession(session.id);
    snapshots.add(
      deriveFreeScoreSnapshot(
        status: session.status,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        events: events,
      ),
    );
  }
  return snapshots;
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final asyncSnapshots = ref.watch(completedFreeScoreSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: asyncSnapshots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PlayTapSpacing.xl),
                child: Text(
                  'Aucune session enregistrée.',
                  style: PlayTapTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PlayTapSpacing.lg),
            itemCount: snapshots.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: PlayTapSpacing.sm),
            itemBuilder: (context, index) =>
                _HistoryTile(snapshot: snapshots[index]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.snapshot});

  final FreeScoreSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final scoreLine = snapshot.sides
        .map((s) => '${s.name} ${snapshot.scoreState.scores[s.id] ?? 0}')
        .join(' — ');
    final minutes = snapshot.endedAt != null
        ? snapshot.endedAt!.difference(snapshot.startedAt).inMinutes
        : 0;

    return Container(
      padding: const EdgeInsets.all(PlayTapSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: PlayTapRadii.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score libre',
            style: PlayTapTypography.label.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            scoreLine,
            style: PlayTapTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            minutes < 1 ? 'Moins d\'une minute' : '$minutes min',
            style: PlayTapTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
