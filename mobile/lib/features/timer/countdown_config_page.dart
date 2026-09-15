import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_spec.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/session_actions.dart';
import 'timer_actions.dart';

const _quickPresetsSeconds = [30, 60, 300];
const _maxDurationSeconds = 24 * 60 * 60; // a generous, sane upper bound.

class CountdownConfigPage extends ConsumerStatefulWidget {
  const CountdownConfigPage({super.key});

  @override
  ConsumerState<CountdownConfigPage> createState() =>
      _CountdownConfigPageState();
}

class _CountdownConfigPageState extends ConsumerState<CountdownConfigPage> {
  final _controller = TextEditingController(text: '60');
  bool _starting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _durationSeconds => int.tryParse(_controller.text.trim());

  bool get _isValid {
    final seconds = _durationSeconds;
    return seconds != null && seconds > 0 && seconds <= _maxDurationSeconds;
  }

  Future<void> _onStart() async {
    if (!_isValid || _starting) return;
    setState(() => _starting = true);

    final spec = TimerSpec(
      schemaVersion: 1,
      mode: TimerMode.countdown,
      durationTargetMs: _durationSeconds! * 1000,
    );

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
        if (mounted) context.pushReplacement(activeSessionRoute(existing));
        return;
      }
      await abandonSession(ref, existing.id);
    }

    final sessionId = await startTimerSession(ref, spec);
    if (mounted) context.pushReplacement('/timer/session/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Compte à rebours')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayTapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durée rapide',
                    style: PlayTapTypography.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: PlayTapSpacing.sm),
                  Wrap(
                    spacing: PlayTapSpacing.sm,
                    children: [
                      for (final seconds in _quickPresetsSeconds)
                        ChoiceChip(
                          label: Text(_formatQuickLabel(seconds)),
                          selected: _durationSeconds == seconds,
                          onSelected: (_) => setState(
                            () => _controller.text = seconds.toString(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: PlayTapSpacing.xl),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durée personnalisée (secondes)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (!_isValid) ...[
                    const SizedBox(height: PlayTapSpacing.xs),
                    Text(
                      'Choisissez une durée supérieure à 0.',
                      style: PlayTapTypography.caption.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PlayTapSpacing.lg,
                0,
                PlayTapSpacing.lg,
                PlayTapSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isValid && !_starting ? _onStart : null,
                  child: _starting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('COMMENCER'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQuickLabel(int seconds) {
  if (seconds < 60) return '${seconds}s';
  return '${seconds ~/ 60} min';
}
