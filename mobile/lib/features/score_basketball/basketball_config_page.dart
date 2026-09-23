import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/preset_ids.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/rulesets/basketball_rulesets.dart';
import '../../l10n/app_localizations.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/session_actions.dart';
import '../score_team_match/team_match_actions.dart';

class BasketballConfigPage extends ConsumerStatefulWidget {
  const BasketballConfigPage({super.key});

  @override
  ConsumerState<BasketballConfigPage> createState() =>
      _BasketballConfigPageState();
}

class _BasketballConfigPageState extends ConsumerState<BasketballConfigPage> {
  final _teamNameControllers = List.generate(2, (_) => TextEditingController());
  bool _defaultNamesApplied = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultNamesApplied) {
      final l10n = AppLocalizations.of(context)!;
      for (var team = 0; team < 2; team++) {
        _teamNameControllers[team].text = l10n.teamMatchDefaultTeamName(
          team + 1,
        );
      }
      _defaultNamesApplied = true;
    }
  }

  @override
  void dispose() {
    for (final c in _teamNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _namesValid =>
      _teamNameControllers.every((c) => c.text.trim().isNotEmpty);

  Future<void> _onStart() async {
    if (!_namesValid || _starting) return;
    setState(() => _starting = true);

    final teamA = ScoringSide(
      id: sideATeamId,
      name: _teamNameControllers[0].text.trim(),
    );
    final teamB = ScoringSide(
      id: sideBTeamId,
      name: _teamNameControllers[1].text.trim(),
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

    final matchRule = resolveDefaultBasketballRuleset(DateTime.now().toUtc());
    final sessionId = await startTeamMatchSession(
      ref,
      matchRule: matchRule,
      teamA: teamA,
      teamB: teamB,
      presetRef: basketballPresetRef,
    );
    if (mounted) {
      context.pushReplacement('/score/basketball/session/$sessionId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    Widget teamSection(int teamIndex) => Padding(
      padding: const EdgeInsets.only(bottom: PlayTapSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.teamMatchTeamSectionLabel(teamIndex + 1),
            style: PlayTapTypography.label.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PlayTapSpacing.sm),
          TextField(
            controller: _teamNameControllers[teamIndex],
            decoration: InputDecoration(labelText: l10n.teamMatchTeamNameLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.basketballConfigTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayTapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [teamSection(0), teamSection(1)],
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
