import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../app/l10n/timer_mode_label.dart';
import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/score_session_deriver.dart';
import '../../domain/engines/timer_deriver.dart';
import '../../domain/models/score_session_snapshot.dart';
import '../../domain/models/session_category.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../score_petanque/petanque_actions.dart' show petanquePresetRef;

sealed class HistoryEntry {
  const HistoryEntry();
}

class ScoreHistoryEntry extends HistoryEntry {
  const ScoreHistoryEntry(this.snapshot, {required this.presetRef});
  final ScoreSessionSnapshot snapshot;

  /// Distinguishes which Score preset produced this entry — both Score
  /// Libre and Pétanque share `SessionCategory.score`, so the category
  /// alone can't pick the right label/headline (see
  /// `features/shared/session_actions.dart` for the analogous routing
  /// decision).
  final String? presetRef;

  bool get isPetanque => presetRef == petanquePresetRef;
}

class TimerHistoryEntry extends HistoryEntry {
  const TimerHistoryEntry(this.snapshot);
  final TimerSnapshot snapshot;
}

/// Completed sessions across all categories, most recent first — always
/// derived from Session + Events replay (see docs/DATA_MODEL.md,
/// "HistoryEntry"). Never a stored `finalScore`/summary column, never
/// fake/demo data.
///
/// A [StreamProvider] driven by [SessionRepository.watchCompletedSessions]
/// (not a one-shot [FutureProvider]) so this page reflects a session
/// finishing while it's kept alive in the bottom-nav's `IndexedStack` —
/// a plain `FutureProvider` here only ever resolved once and never
/// refreshed, so Historique froze on whichever session completed first.
final historyProvider = StreamProvider<List<HistoryEntry>>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);

  Future<List<HistoryEntry>> deriveEntries(
    List<SessionSummary> sessions,
  ) async {
    final entries = <HistoryEntry>[];
    for (final session in sessions) {
      final events = await eventRepo.getEventsForSession(session.id);
      switch (session.category) {
        case SessionCategory.score:
          entries.add(
            ScoreHistoryEntry(
              deriveScoreSessionSnapshot(
                status: session.status,
                startedAt: session.startedAt,
                endedAt: session.endedAt,
                events: events,
              ),
              presetRef: session.presetRef,
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
  }

  return sessionRepo.watchCompletedSessions().asyncMap(deriveEntries);
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final asyncEntries = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: asyncEntries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(l10n.errorPrefix(e.toString()))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PlayTapSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.emptyHistoryTitle,
                      style: PlayTapTypography.title.copyWith(
                        color: colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: PlayTapSpacing.sm),
                    Text(
                      l10n.emptyHistorySubtitle,
                      style: PlayTapTypography.body.copyWith(
                        color: colors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: PlayTapSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: colors.border),
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
    final l10n = AppLocalizations.of(context)!;
    final (label, headline, caption) = switch (entry) {
      ScoreHistoryEntry(:final snapshot, :final isPetanque) when isPetanque => (
        l10n.presetPetanque,
        snapshot.sides
            .map((s) => '${s.name} ${snapshot.scoreState.scores[s.id] ?? 0}')
            .join(' — '),
        '${l10n.endsCountPlural(snapshot.scoreState.rounds.length)} · '
            '${_durationCaption(l10n, snapshot.startedAt, snapshot.endedAt)}',
      ),
      ScoreHistoryEntry(:final snapshot) => (
        l10n.presetFreeScore,
        snapshot.sides
            .map((s) => '${s.name} ${snapshot.scoreState.scores[s.id] ?? 0}')
            .join(' — '),
        _durationCaption(l10n, snapshot.startedAt, snapshot.endedAt),
      ),
      TimerHistoryEntry(:final snapshot) => (
        timerModeLabel(l10n, snapshot.spec.mode),
        _timerHeadline(l10n, snapshot),
        _durationCaption(l10n, snapshot.startedAt, snapshot.endedAt),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PlayTapTypography.label.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            headline,
            style: PlayTapTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: PlayTapSpacing.xs),
          Text(
            caption,
            style: PlayTapTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

String _timerHeadline(AppLocalizations l10n, TimerSnapshot snapshot) {
  final elapsed = _formatDuration(snapshot.state.elapsedMs);
  if (snapshot.spec.mode == TimerMode.lapTimer) {
    return '$elapsed — ${l10n.lapsCountPlural(snapshot.state.laps.length)}';
  }
  return elapsed;
}

String _formatDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _durationCaption(
  AppLocalizations l10n,
  DateTime startedAt,
  DateTime? endedAt,
) {
  final minutes = endedAt != null ? endedAt.difference(startedAt).inMinutes : 0;
  final duration = minutes < 1
      ? l10n.lessThanAMinute
      : l10n.minutesShort(minutes);
  return '${_relativeDay(l10n, startedAt)} · $duration';
}

String _relativeDay(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l10n.today;
  if (diff == 1) return l10n.yesterday;
  return intl.DateFormat.Md(l10n.localeName).format(date);
}
