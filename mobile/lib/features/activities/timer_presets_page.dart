import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_spec.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/session_actions.dart';
import '../timer/timer_actions.dart';

class _TimerPreset {
  const _TimerPreset(this.label, this.spec, this.route);

  final String label;

  /// Non-null for presets that start immediately (Chronomètre, Lap Timer);
  /// null for Countdown, which needs a duration first — see `route`.
  final TimerSpec? spec;
  final String? route;
}

const List<_TimerPreset> _presets = [
  _TimerPreset(
    'Chronomètre',
    TimerSpec(schemaVersion: 1, mode: TimerMode.stopwatch),
    null,
  ),
  _TimerPreset('Countdown', null, '/timer/countdown/config'),
  _TimerPreset(
    'Lap Timer',
    TimerSpec(schemaVersion: 1, mode: TimerMode.lapTimer),
    null,
  ),
];

/// See docs/RELEASE_0_1.md — the three Timer modes for Release 0.1. Sprint
/// Timer is not listed: it belongs to the Interval Engine (Phase 1B.3+),
/// not here (see the Phase 1B.2 brief section 18).
class TimerPresetsPage extends ConsumerStatefulWidget {
  const TimerPresetsPage({super.key});

  @override
  ConsumerState<TimerPresetsPage> createState() => _TimerPresetsPageState();
}

class _TimerPresetsPageState extends ConsumerState<TimerPresetsPage> {
  bool _starting = false;

  Future<void> _onSelect(_TimerPreset preset) async {
    if (preset.route != null) {
      context.push(preset.route!);
      return;
    }
    if (_starting) return;
    setState(() => _starting = true);

    final existing = await ref
        .read(sessionRepositoryProvider)
        .getActiveSession();
    if (!mounted) return;

    if (existing != null) {
      final choice = await showActiveSessionConflictDialog(context);
      if (choice == null) {
        setState(() => _starting = false);
        return;
      }
      if (choice == ActiveSessionChoice.resume) {
        if (mounted) context.push(activeSessionRoute(existing));
        setState(() => _starting = false);
        return;
      }
      await abandonSession(ref, existing.id);
    }

    final sessionId = await startTimerSession(ref, preset.spec!);
    if (mounted) context.pushReplacement('/timer/session/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: ListView.separated(
        padding: const EdgeInsets.all(PlayTapSpacing.lg),
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: PlayTapSpacing.sm),
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return Material(
            color: colors.surface,
            borderRadius: PlayTapRadii.mdRadius,
            child: InkWell(
              borderRadius: PlayTapRadii.mdRadius,
              onTap: _starting ? null : () => _onSelect(preset),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlayTapSpacing.lg,
                  vertical: PlayTapSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.label,
                        style: PlayTapTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
