import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/timer_mode_label.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/lap_split.dart';
import '../../domain/models/session_status.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_snapshot.dart';
import '../../domain/models/timer_status.dart';
import '../../l10n/app_localizations.dart';
import 'timer_session_controller.dart';

/// Repaint cadence for the live display — a plain UI-layer ticker (see the
/// Phase 1B.2 brief section 21). It only asks the controller "what should
/// I show right now"; it never computes or owns the timer value itself.
const _repaintInterval = Duration(milliseconds: 200);

class ActiveTimerSessionPage extends ConsumerStatefulWidget {
  const ActiveTimerSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ActiveTimerSessionPage> createState() =>
      _ActiveTimerSessionPageState();
}

class _ActiveTimerSessionPageState
    extends ConsumerState<ActiveTimerSessionPage> {
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
        .read(timerSessionControllerProvider(widget.sessionId).notifier)
        .checkLiveCompletion();
    setState(() {}); // repaint only — never mutates timer state itself.
  }

  Future<void> _confirmComplete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finishSessionDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.finishButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    await ref
        .read(timerSessionControllerProvider(widget.sessionId).notifier)
        .complete();
    // No explicit navigation here: `complete()` flips sessionStatus away
    // from active, which `build()`'s own `data:` branch below already
    // detects and navigates on — the single place that does so, whether
    // completion was triggered by this button or by the live ticker
    // (Countdown running out on its own).
  }

  @override
  Widget build(BuildContext context) {
    final asyncSnapshot = ref.watch(
      timerSessionControllerProvider(widget.sessionId),
    );
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(timerModeLabel(l10n, asyncSnapshot.value?.spec.mode)),
      ),
      body: asyncSnapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text(
            l10n.errorPrefix(e.toString()),
            style: TextStyle(color: colors.danger),
          ),
        ),
        data: (baseline) {
          if (baseline.sessionStatus != SessionStatus.active) {
            // The countdown just auto-completed (checkLiveCompletion
            // persisted it) — move on to the summary once, post-frame.
            // Stop the repaint ticker *now*, not in dispose(): the
            // Navigator doesn't unmount this page synchronously, so
            // without this a still-firing tick keeps calling setState,
            // which re-runs this branch and schedules another competing
            // pushReplacement every ~200ms — a self-sustaining loop that
            // never lets the first navigation actually take.
            _ticker?.cancel();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement('/timer/summary/${widget.sessionId}');
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final display =
              ref
                  .read(
                    timerSessionControllerProvider(widget.sessionId).notifier,
                  )
                  .currentDisplaySnapshot() ??
              baseline;

          return _ActiveTimerBody(
            snapshot: display,
            onPauseResume: () {
              HapticFeedback.lightImpact();
              final notifier = ref.read(
                timerSessionControllerProvider(widget.sessionId).notifier,
              );
              display.state.status == TimerStatus.running
                  ? notifier.pause()
                  : notifier.resume();
            },
            onLap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(
                    timerSessionControllerProvider(widget.sessionId).notifier,
                  )
                  .recordLap();
            },
            onComplete: _confirmComplete,
          );
        },
      ),
    );
  }
}

class _ActiveTimerBody extends StatelessWidget {
  const _ActiveTimerBody({
    required this.snapshot,
    required this.onPauseResume,
    required this.onLap,
    required this.onComplete,
  });

  final TimerSnapshot snapshot;
  final VoidCallback onPauseResume;
  final VoidCallback onLap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final isRunning = snapshot.state.status == TimerStatus.running;
    final displayMs = snapshot.spec.mode == TimerMode.countdown
        ? (snapshot.state.remainingMs ?? 0)
        : snapshot.state.elapsedMs;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PlayTapSpacing.lg,
              ),
              child: Semantics(
                label: snapshot.spec.mode == TimerMode.countdown
                    ? l10n.timeRemainingSemantics
                    : l10n.timeElapsedSemantics,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatMs(displayMs),
                    style: PlayTapTypography.scoreDisplay.copyWith(
                      fontSize: 104,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (snapshot.spec.mode == TimerMode.lapTimer &&
            snapshot.state.laps.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(
                horizontal: PlayTapSpacing.lg,
              ),
              itemCount: snapshot.state.laps.length,
              itemBuilder: (context, index) {
                final lap = snapshot.state.laps[index];
                return _LapRow(lap: lap);
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: onPauseResume,
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
                  ),
                  if (snapshot.spec.mode == TimerMode.lapTimer) ...[
                    const SizedBox(width: PlayTapSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                          ),
                          onPressed: isRunning ? onLap : null,
                          child: Semantics(
                            label: l10n.recordLapSemantics,
                            child: Text(l10n.lapButton),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PlayTapSpacing.md),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onComplete,
                  child: Semantics(
                    label: l10n.finishSessionButton,
                    child: Text(l10n.finishSessionButton),
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

class _LapRow extends StatelessWidget {
  const _LapRow({required this.lap});

  final LapSplit lap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.lapRowLabel(lap.lapNumber),
            style: PlayTapTypography.body.copyWith(color: colors.muted),
          ),
          Text(
            _formatMs(lap.splitMs),
            style: PlayTapTypography.body.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }
}

String _formatMs(int ms) {
  final clamped = ms < 0 ? 0 : ms;
  final totalSeconds = clamped ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final centis = (clamped % 1000) ~/ 10;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  final cc = centis.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
  }
  return '$mm:$ss.$cc';
}
