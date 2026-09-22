import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_spec.dart';
import '../../l10n/app_localizations.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/big_action_tile.dart';
import '../shared/session_actions.dart';
import '../timer/timer_actions.dart';

class _TimerPreset {
  const _TimerPreset(this.label, this.spec, this.route);

  final String label;

  /// Non-null for presets that start immediately (Chronomètre, Tours);
  /// null for Compte à rebours, which needs a duration first — see `route`.
  final TimerSpec? spec;
  final String? route;
}

List<_TimerPreset> _presetsOf(AppLocalizations l10n) => [
  _TimerPreset(
    l10n.timerModeStopwatch,
    const TimerSpec(schemaVersion: 1, mode: TimerMode.stopwatch),
    null,
  ),
  _TimerPreset(l10n.timerModeCountdown, null, '/timer/countdown/config'),
  _TimerPreset(
    l10n.timerModeLaps,
    const TimerSpec(schemaVersion: 1, mode: TimerMode.lapTimer),
    null,
  ),
];

const _presetIcons = [
  Icons.timer_outlined,
  Icons.hourglass_bottom_outlined,
  Icons.flag_outlined,
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
    final l10n = AppLocalizations.of(context)!;
    final presets = _presetsOf(l10n);
    // Restrained brand use (release brief section 16): one neutral tile,
    // one violet, one lime — not three equally loud accent blocks.
    final brandPairs = [
      null,
      (background: colors.primary, foreground: colors.onPrimary),
      (background: colors.accent, foreground: colors.onAccent),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timerSectionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(PlayTapSpacing.lg),
        child: Column(
          children: [
            for (final (index, preset) in presets.indexed) ...[
              if (index > 0) const SizedBox(height: PlayTapSpacing.md),
              Expanded(
                child: BigActionTile(
                  icon: _presetIcons[index],
                  label: preset.label,
                  backgroundColor: brandPairs[index]?.background,
                  foregroundColor: brandPairs[index]?.foreground,
                  onTap: _starting ? () {} : () => _onSelect(preset),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
