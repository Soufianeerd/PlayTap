import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/score_rule.dart';
import '../../domain/models/score_session_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../shared/session_actions.dart';
import 'petanque_actions.dart';
import 'petanque_session_controller.dart';

class ActivePetanqueSessionPage extends ConsumerWidget {
  const ActivePetanqueSessionPage({super.key, required this.sessionId});

  final String sessionId;

  Future<void> _confirmAbandon(BuildContext context, WidgetRef ref) async {
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
    await abandonSession(ref, sessionId);
    if (context.mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).playTapColors;

    ref.listen<AsyncValue<ScoreSessionSnapshot>>(
      petanqueSessionControllerProvider(sessionId),
      (previous, next) {
        final wasComplete = previous?.value?.scoreState.matchComplete ?? false;
        final isComplete = next.value?.scoreState.matchComplete ?? false;
        if (!wasComplete && isComplete) {
          context.pushReplacement('/score/petanque/summary/$sessionId');
        }
      },
    );

    final asyncView = ref.watch(petanqueSessionControllerProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.presetPetanque),
        toolbarHeight: 44,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: l10n.abandonGameButton,
            onPressed: () => _confirmAbandon(context, ref),
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
        data: (view) => _PetanqueBody(sessionId: sessionId, view: view),
      ),
    );
  }
}

class _PetanqueBody extends ConsumerWidget {
  const _PetanqueBody({required this.sessionId, required this.view});

  final String sessionId;
  final ScoreSessionSnapshot view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final teamA = view.sides.firstWhere((s) => s.id == sideATeamId);
    final teamB = view.sides.firstWhere((s) => s.id == sideBTeamId);
    final scoreA = view.scoreState.scores[sideATeamId] ?? 0;
    final scoreB = view.scoreState.scores[sideBTeamId] ?? 0;
    final endNumber = view.scoreState.rounds.length + 1;
    // Derived from the rule actually persisted in SESSION_STARTED, never
    // recomputed from config-screen state — see the note on
    // `ScoreSessionSnapshot.scoreRule` (a tête-à-tête session must never
    // show +4/+5/+6, and this must hold after recovery too).
    final allowedIncrements =
        (view.scoreRule as TeamScoreRule).allowedIncrements;

    void addPoints(String sideId, int amount) => ref
        .read(petanqueSessionControllerProvider(sessionId).notifier)
        .addRoundPoints(sideId, amount);

    return Column(
      children: [
        _UndoBar(
          enabled: view.isUndoAvailable,
          onTap: () => ref
              .read(petanqueSessionControllerProvider(sessionId).notifier)
              .undoLast(),
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
          padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.sm),
          child: Text(
            l10n.endNumberLabel(endNumber),
            style: PlayTapTypography.caption.copyWith(color: colors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PlayTapSpacing.lg,
            0,
            PlayTapSpacing.lg,
            PlayTapSpacing.lg,
          ),
          child: Column(
            children: [
              _TeamRoundButtons(
                teamName: teamA.name,
                allowedIncrements: allowedIncrements,
                onTap: (amount) => addPoints(sideATeamId, amount),
              ),
              const SizedBox(height: PlayTapSpacing.md),
              _TeamRoundButtons(
                teamName: teamB.name,
                allowedIncrements: allowedIncrements,
                onTap: (amount) => addPoints(sideBTeamId, amount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UndoBar extends StatelessWidget {
  const _UndoBar({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final color = enabled ? colors.foreground : colors.muted;

    return Material(
      color: colors.surfaceVariant,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlayTapSpacing.lg,
            vertical: PlayTapSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo, size: 18, color: color),
              const SizedBox(width: PlayTapSpacing.xs),
              Text(
                AppLocalizations.of(context)!.undoLastRound,
                style: PlayTapTypography.caption.copyWith(color: color),
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

class _TeamRoundButtons extends StatelessWidget {
  const _TeamRoundButtons({
    required this.teamName,
    required this.allowedIncrements,
    required this.onTap,
  });

  final String teamName;
  final List<int> allowedIncrements;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: PlayTapTypography.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: PlayTapSpacing.xs),
        Wrap(
          spacing: PlayTapSpacing.xs,
          runSpacing: PlayTapSpacing.xs,
          children: [
            for (final amount in allowedIncrements)
              Semantics(
                button: true,
                label: l10n.addRoundPointsSemantics(amount, teamName),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onTap(amount);
                  },
                  child: Text('+$amount'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
