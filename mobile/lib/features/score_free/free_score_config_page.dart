import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/scoring_side.dart';
import '../../l10n/app_localizations.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/pill_selector.dart';
import '../shared/session_actions.dart';
import 'free_score_actions.dart';

class FreeScoreConfigPage extends ConsumerStatefulWidget {
  const FreeScoreConfigPage({super.key});

  @override
  ConsumerState<FreeScoreConfigPage> createState() =>
      _FreeScoreConfigPageState();
}

class _FreeScoreConfigPageState extends ConsumerState<FreeScoreConfigPage> {
  int _sideCount = 2;
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _defaultNamesApplied = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localized default names need a BuildContext, so they're applied here
    // (once) rather than at controller construction time — see
    // docs/LOCALIZATION.md.
    if (!_defaultNamesApplied) {
      final l10n = AppLocalizations.of(context)!;
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = l10n.defaultParticipantName(i + 1);
      }
      _defaultNamesApplied = true;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _namesValid =>
      _controllers.take(_sideCount).every((c) => c.text.trim().isNotEmpty);

  Future<void> _onStart() async {
    if (!_namesValid || _starting) return;
    setState(() => _starting = true);

    final sides = [
      for (var i = 0; i < _sideCount; i++)
        ScoringSide(id: 'side_${i + 1}', name: _controllers[i].text.trim()),
    ];

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

    final sessionId = await startFreeScoreSession(ref, sides);
    if (mounted) context.pushReplacement('/score/free/session/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newScoreTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayTapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.participantCountLabel,
                    style: PlayTapTypography.label.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<int>(
                    options: const [2, 3, 4],
                    labelBuilder: (n) => '$n',
                    value: _sideCount,
                    onChanged: (n) => setState(() => _sideCount = n),
                  ),
                  const SizedBox(height: PlayTapSpacing.xl),
                  for (var i = 0; i < _sideCount; i++) ...[
                    TextField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        labelText: l10n.participantNameLabel(i + 1),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: PlayTapSpacing.md),
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
                  onPressed: _namesValid && !_starting ? _onStart : null,
                  child: _starting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.startButton),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
