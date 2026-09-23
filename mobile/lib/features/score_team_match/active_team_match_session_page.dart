import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/match_clock_kind.dart';
import '../../domain/models/match_session_snapshot.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/session_status.dart';
import '../../domain/models/timer_status.dart';
import '../../l10n/app_localizations.dart';
import '../shared/session_actions.dart';
import 'shootout_panel.dart';
import 'team_match_actions.dart';
import 'team_match_labels.dart';
import 'team_match_session_controller.dart';

/// Repaint cadence for the live clock display — mirrors
/// `active_timer_session_page.dart`'s identical ticker: a plain UI-layer
/// refresh, never the source of truth for elapsed time.
const _repaintInterval = Duration(milliseconds: 200);

class ActiveTeamMatchSessionPage extends ConsumerStatefulWidget {
  const ActiveTeamMatchSessionPage({
    super.key,
    required this.sessionId,
    required this.summaryRoute,
  });

  final String sessionId;

  /// Where to navigate once the match ends — kept as a parameter rather
  /// than hardcoded so this one shared page serves all three sports'
  /// distinct summary routes (see `app/router.dart`).
  final String summaryRoute;

  @override
  ConsumerState<ActiveTeamMatchSessionPage> createState() =>
      _ActiveTeamMatchSessionPageState();
}

class _ActiveTeamMatchSessionPageState
    extends ConsumerState<ActiveTeamMatchSessionPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_repaintInterval, (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    ref
        .read(teamMatchSessionControllerProvider(widget.sessionId).notifier)
        .checkLivePeriodExpiry();
    setState(() {}); // repaint only — never mutates match state itself.
  }

  Future<void> _confirmAbandon() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.abandonGameDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.abandonGameButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await abandonSession(ref, widget.sessionId);
    if (mounted) context.go('/history');
  }

  Future<void> _confirmEndPeriod() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.endPeriodDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.endPeriodManuallyButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(teamMatchSessionControllerProvider(widget.sessionId).notifier)
        .endPeriodManually();
  }

  Future<void> _pickAddedTime() async {
    final l10n = AppLocalizations.of(context)!;
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addedTimeDialogTitle),
        content: Wrap(
          spacing: PlayTapSpacing.sm,
          children: [
            for (final n in const [1, 2, 3, 4, 5, 6])
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(n),
                child: Text(l10n.addedTimeMinutesOption(n)),
              ),
          ],
        ),
      ),
    );
    if (minutes == null) return;
    await ref
        .read(teamMatchSessionControllerProvider(widget.sessionId).notifier)
        .announceAddedTime(Duration(minutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).playTapColors;

    ref.listen<AsyncValue<MatchSessionSnapshot>>(
      teamMatchSessionControllerProvider(widget.sessionId),
      (previous, next) {
        final wasEnded = previous?.value?.matchState.matchEnded ?? false;
        final isEnded = next.value?.matchState.matchEnded ?? false;
        if (!wasEnded && isEnded) {
          _ticker?.cancel();
          context.pushReplacement(widget.summaryRoute);
        }
      },
    );

    final asyncView = ref.watch(
      teamMatchSessionControllerProvider(widget.sessionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          teamMatchSportLabel(l10n, asyncView.value?.matchRule.rulesetId ?? ''),
        ),
        toolbarHeight: 44,
        actions: [
          if (asyncView.value case final view?
              when view.matchRule.clock == MatchClockKind.runningClock)
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: l10n.announceAddedTimeButton,
              onPressed: view.status == SessionStatus.active
                  ? _pickAddedTime
                  : null,
            ),
          PopupMenuButton<_MenuAction>(
            tooltip: l10n.moreActionsButton,
            onSelected: (action) => switch (action) {
              _MenuAction.abandon => _confirmAbandon(),
              _MenuAction.endPeriod => _confirmEndPeriod(),
            },
            itemBuilder: (context) => [
              if (asyncView.value?.matchRule.clock ==
                  MatchClockKind.runningClock)
                PopupMenuItem(
                  value: _MenuAction.endPeriod,
                  child: Text(l10n.endPeriodManuallyButton),
                ),
              PopupMenuItem(
                value: _MenuAction.abandon,
                child: Text(l10n.abandonGameButton),
              ),
            ],
          ),
        ],
      ),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text(
            l10n.errorPrefix(e.toString()),
            style: TextStyle(color: colors.danger),
          ),
        ),
        data: (baseline) {
          final display =
              ref
                  .read(
                    teamMatchSessionControllerProvider(
                      widget.sessionId,
                    ).notifier,
                  )
                  .currentDisplaySnapshot() ??
              baseline;

          if (display.matchState.phase == MatchPhase.shootoutInProgress &&
              display.shootoutState != null) {
            return ShootoutPanel(
              sides: display.sides,
              shootoutState: display.shootoutState!,
              onAttempt: (sideId, {required scored}) => ref
                  .read(
                    teamMatchSessionControllerProvider(
                      widget.sessionId,
                    ).notifier,
                  )
                  .recordShootoutAttempt(sideId, scored: scored),
            );
          }

          return _TeamMatchBody(sessionId: widget.sessionId, view: display);
        },
      ),
    );
  }
}

enum _MenuAction { abandon, endPeriod }

class _TeamMatchBody extends ConsumerWidget {
  const _TeamMatchBody({required this.sessionId, required this.view});

  final String sessionId;
  final MatchSessionSnapshot view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final rule = view.matchRule;
    final teamA = view.sides.firstWhere((s) => s.id == sideATeamId);
    final teamB = view.sides.firstWhere((s) => s.id == sideBTeamId);
    final scoreA = view.scoreState.scores[sideATeamId] ?? 0;
    final scoreB = view.scoreState.scores[sideBTeamId] ?? 0;
    final allowedIncrements = rule.scoreRule.allowedIncrements;
    final clock = view.matchState.clock;
    final displayMs = rule.clock == MatchClockKind.stoppedClock
        ? (clock.remainingMs ?? 0)
        : clock.elapsedMs;
    final isRunning = clock.status == TimerStatus.running;

    final notifier = ref.read(
      teamMatchSessionControllerProvider(sessionId).notifier,
    );

    return Column(
      children: [
        _UndoBar(onTap: () => notifier.undoLast()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.sm),
          child: Column(
            children: [
              Text(
                teamMatchPeriodLabel(l10n, rule, view.matchState),
                style: PlayTapTypography.label.copyWith(color: colors.muted),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: rule.clock == MatchClockKind.stoppedClock
                        ? l10n.timeRemainingSemantics
                        : l10n.timeElapsedSemantics,
                    child: Text(
                      formatMatchClockMs(displayMs),
                      style: PlayTapTypography.scoreDisplay.copyWith(
                        fontSize: 48,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  if (view.matchState.announcedAddedTimeMs != null) ...[
                    const SizedBox(width: PlayTapSpacing.xs),
                    Text(
                      l10n.addedTimeBadge(
                        (view.matchState.announcedAddedTimeMs! / 60000).round(),
                      ),
                      style: PlayTapTypography.body.copyWith(
                        color: colors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TeamScorePanel(
                  name: teamA.name,
                  score: scoreA,
                  background: colors.primary,
                  foreground: colors.onPrimary,
                ),
              ),
              Expanded(
                child: _TeamScorePanel(
                  name: teamB.name,
                  score: scoreB,
                  background: colors.accent,
                  foreground: colors.onAccent,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PlayTapSpacing.lg,
            PlayTapSpacing.md,
            PlayTapSpacing.lg,
            PlayTapSpacing.lg,
          ),
          child: Column(
            children: [
              _TeamScoreButtons(
                teamName: teamA.name,
                allowedIncrements: allowedIncrements,
                onTap: (amount) => notifier.addPoint(sideATeamId, amount),
              ),
              const SizedBox(height: PlayTapSpacing.sm),
              _TeamScoreButtons(
                teamName: teamB.name,
                allowedIncrements: allowedIncrements,
                onTap: (amount) => notifier.addPoint(sideBTeamId, amount),
              ),
              const SizedBox(height: PlayTapSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: clock.status == TimerStatus.completed
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          notifier.togglePlayPause();
                        },
                  child: Semantics(
                    label: isRunning
                        ? l10n.pauseSemantics
                        : l10n.resumeTimerSemantics,
                    child: Text(
                      isRunning
                          ? l10n.pauseButtonLabel
                          : l10n.resumeTimerButtonLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UndoBar extends StatelessWidget {
  const _UndoBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Material(
      color: colors.surfaceVariant,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlayTapSpacing.lg,
            vertical: PlayTapSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo, size: 18, color: colors.foreground),
              const SizedBox(width: PlayTapSpacing.xs),
              Text(
                AppLocalizations.of(context)!.undoLastActionLabel,
                style: PlayTapTypography.caption.copyWith(
                  color: colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScorePanel extends StatelessWidget {
  const _TeamScorePanel({
    required this.name,
    required this.score,
    required this.background,
    required this.foreground,
  });

  final String name;
  final int score;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: PlayTapTypography.title.copyWith(
              color: foreground.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: PlayTapSpacing.sm),
          Text(
            '$score',
            style: PlayTapTypography.scoreDisplay.copyWith(
              color: foreground,
              fontSize: 88,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreButtons extends StatelessWidget {
  const _TeamScoreButtons({
    required this.teamName,
    required this.allowedIncrements,
    required this.onTap,
  });

  final String teamName;
  final List<int> allowedIncrements;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        for (final amount in allowedIncrements) ...[
          if (amount != allowedIncrements.first)
            const SizedBox(width: PlayTapSpacing.xs),
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.addRoundPointsSemantics(amount, teamName),
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onTap(amount);
                  },
                  child: Text('+$amount'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
