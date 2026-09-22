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
import 'petanque_actions.dart';
import 'petanque_format.dart';

class PetanqueConfigPage extends ConsumerStatefulWidget {
  const PetanqueConfigPage({super.key});

  @override
  ConsumerState<PetanqueConfigPage> createState() => _PetanqueConfigPageState();
}

class _PetanqueConfigPageState extends ConsumerState<PetanqueConfigPage> {
  PetanqueFormat _format = PetanqueFormat.doublette;

  // 2 teams x up to 3 players (triplette) — team name + player names.
  final _teamNameControllers = List.generate(2, (_) => TextEditingController());
  final _playerControllers = List.generate(
    2,
    (_) => List.generate(3, (_) => TextEditingController()),
  );
  bool _defaultNamesApplied = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localized defaults need a BuildContext, so applied once here — see
    // docs/LOCALIZATION.md (mirrors free_score_config_page.dart).
    if (!_defaultNamesApplied) {
      final l10n = AppLocalizations.of(context)!;
      for (var team = 0; team < 2; team++) {
        _teamNameControllers[team].text = l10n.petanqueDefaultTeamName(
          team + 1,
        );
        for (var player = 0; player < 3; player++) {
          _playerControllers[team][player].text = l10n.defaultParticipantName(
            player + 1,
          );
        }
      }
      _defaultNamesApplied = true;
    }
  }

  @override
  void dispose() {
    for (final c in _teamNameControllers) {
      c.dispose();
    }
    for (final team in _playerControllers) {
      for (final c in team) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool get _namesValid {
    for (var team = 0; team < 2; team++) {
      if (_teamNameControllers[team].text.trim().isEmpty) return false;
      for (var p = 0; p < _format.playersPerSide; p++) {
        if (_playerControllers[team][p].text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  Future<void> _onStart() async {
    if (!_namesValid || _starting) return;
    setState(() => _starting = true);

    ScoringSide buildSide(int teamIndex, String id) {
      final players = [
        for (var p = 0; p < _format.playersPerSide; p++)
          _playerControllers[teamIndex][p].text.trim(),
      ];
      return ScoringSide(
        id: id,
        name: _teamNameControllers[teamIndex].text.trim(),
        players: _format == PetanqueFormat.headToHead ? null : players,
      );
    }

    final teamA = buildSide(0, sideATeamId);
    final teamB = buildSide(1, sideBTeamId);

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

    final sessionId = await startPetanqueSession(
      ref,
      teamA: teamA,
      teamB: teamB,
    );
    if (mounted) context.pushReplacement('/score/petanque/session/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    Widget teamSection(int teamIndex) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.petanqueTeamSectionLabel(teamIndex + 1),
            style: PlayTapTypography.label.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PlayTapSpacing.sm),
          TextField(
            controller: _teamNameControllers[teamIndex],
            decoration: InputDecoration(labelText: l10n.petanqueTeamNameLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PlayTapSpacing.sm),
          for (var p = 0; p < _format.playersPerSide; p++) ...[
            TextField(
              controller: _playerControllers[teamIndex][p],
              decoration: InputDecoration(
                labelText: l10n.participantNameLabel(p + 1),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: PlayTapSpacing.sm),
          ],
          const SizedBox(height: PlayTapSpacing.md),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.petanqueConfigTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayTapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.petanqueFormatLabel,
                    style: PlayTapTypography.label.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<PetanqueFormat>(
                    options: PetanqueFormat.values,
                    labelBuilder: (f) => switch (f) {
                      PetanqueFormat.headToHead =>
                        l10n.petanqueFormatHeadToHead,
                      PetanqueFormat.doublette => l10n.petanqueFormatDoublette,
                      PetanqueFormat.triplette => l10n.petanqueFormatTriplette,
                    },
                    value: _format,
                    onChanged: (f) => setState(() => _format = f),
                  ),
                  const SizedBox(height: PlayTapSpacing.xl),
                  teamSection(0),
                  teamSection(1),
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
