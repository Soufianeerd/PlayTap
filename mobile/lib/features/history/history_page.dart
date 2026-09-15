import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/engines/free_score_deriver.dart';
import '../../domain/engines/timer_deriver.dart';
import '../../domain/models/free_score_snapshot.dart';
import '../../domain/models/session_category.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_snapshot.dart';

sealed class HistoryEntry {
  const HistoryEntry();
}

class ScoreHistoryEntry extends HistoryEntry {
  const ScoreHistoryEntry(this.snapshot);
  final FreeScoreSnapshot snapshot;
}

class TimerHistoryEntry extends HistoryEntry {
  const TimerHistoryEntry(this.snapshot);
  final TimerSnapshot snapshot;
}

/// Completed sessions across all categories, most recent first — always
/// derived from Session + Events replay (see docs/DATA_MODEL.md,
/// "HistoryEntry"). Never a stored `finalScore`/summary column, never
/// fake/demo data.
final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final sessions = await sessionRepo.getCompletedSessions();

  final entries = <HistoryEntry>[];
  for (final session in sessions) {
    final events = await eventRepo.getEventsForSession(session.id);
    switch (session.category) {
      case SessionCategory.score:
        entries.add(
          ScoreHistoryEntry(
            deriveFreeScoreSnapshot(
              status: session.status,
              startedAt: session.startedAt,
              endedAt: session.endedAt,
              events: events,
            ),
          ),
        );
      case SessionCategory.timer:
        entries.add(
          TimerHistoryEntry(
            deriveTimerSnapshot(
              sessionStatus: session.status,
              startedAt: session.startedAt,
              endedAt: session.endedAt,
              events: events,
              nowMs: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
      case SessionCategory.training:
      case SessionCategory.custom:
        break; // not implemented yet — nothing to show.
    }
  }
  return entries;
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final asyncEntries = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: asyncEntries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PlayTapSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Aucune activité pour le moment.',
                      style: PlayTapTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: PlayTapSpacing.sm),
                    Text(
                      'Démarre un score ou un chronomètre pour commencer.',
                      style: PlayTapTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PlayTapSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: PlayTapSpacing.sm),
            itemBuilder: (context, index) =>
                _HistoryTile(entry: entries[index]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final (label, headline, caption) = switch (entry) {
      ScoreHistoryEntry(:final snapshot) => (
        'Score libre',
        snapshot.sides
            .map((s) => '${s.name} ${snapshot.scoreState.scores[s.id] ?? 0}')
            .join(' — '),
        _durationCaption(snapshot.startedAt, snapshot.endedAt),
      ),
      TimerHistoryEntry(:final snapshot) => (
        _timerModeLabel(snapshot.spec.mode),
        _timerHeadline(snapshot),
        _durationCaption(snapshot.startedAt, snapshot.endedAt),
      ),
    };

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
            label,
            style: PlayTapTypography.label.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            headline,
            style: PlayTapTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            caption,
            style: PlayTapTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _timerModeLabel(TimerMode mode) => switch (mode) {
  TimerMode.stopwatch => 'Chronomètre',
  TimerMode.countdown => 'Compte à rebours',
  TimerMode.lapTimer => 'Tours',
  TimerMode.interval => 'Interval',
};

String _timerHeadline(TimerSnapshot snapshot) {
  final elapsed = _formatDuration(snapshot.state.elapsedMs);
  if (snapshot.spec.mode == TimerMode.lapTimer) {
    final lapCount = snapshot.state.laps.length;
    return '$elapsed — $lapCount lap${lapCount == 1 ? '' : 's'}';
  }
  return elapsed;
}

String _formatDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _durationCaption(DateTime startedAt, DateTime? endedAt) {
  final minutes = endedAt != null ? endedAt.difference(startedAt).inMinutes : 0;
  final duration = minutes < 1 ? 'Moins d\'une minute' : '$minutes min';
  return '${_relativeDay(startedAt)} · $duration';
}

String _relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Aujourd\'hui';
  if (diff == 1) return 'Hier';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
