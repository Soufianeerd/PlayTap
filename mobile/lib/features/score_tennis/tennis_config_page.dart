import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/racket_rule.dart';
import '../../domain/models/scoring_side.dart';
import '../../l10n/app_localizations.dart';
import '../shared/active_session_conflict_dialog.dart';
import '../shared/pill_selector.dart';
import '../shared/session_actions.dart';
import 'tennis_actions.dart';
import 'tennis_format.dart';

class TennisConfigPage extends ConsumerStatefulWidget {
  const TennisConfigPage({super.key});

  @override
  ConsumerState<TennisConfigPage> createState() => _TennisConfigPageState();
}

class _TennisConfigPageState extends ConsumerState<TennisConfigPage> {
  TennisMatchType _matchType = TennisMatchType.singles;
  AdvantageMode _advantageMode = AdvantageMode.advantage;
  TennisDecidingSetChoice _decidingSet = TennisDecidingSetChoice.tieBreakSet;

  // 2 sides x up to 2 players (doubles).
  final _playerControllers = List.generate(
    2,
    (_) => List.generate(2, (_) => TextEditingController()),
  );
  String _initialServerId = '0_0';
  bool _defaultNamesApplied = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localized defaults need a BuildContext — see docs/LOCALIZATION.md
    // (mirrors petanque_config_page.dart).
    if (!_defaultNamesApplied) {
      final l10n = AppLocalizations.of(context)!;
      // Player-major, not side-major: this puts each side's *first* player
      // (the only one visible in Singles — see `sideSection`) at the two
      // lowest numbers, so Singles always shows "Player 1"/"Player 2", never
      // skipping to "Player 1"/"Player 3" — the doubles-only second players
      // still get distinct numbers (3/4), never colliding with side A/B's
      // first players in the initial-server picker (see `_serverOptions`).
      var n = 1;
      for (var p = 0; p < 2; p++) {
        for (var side = 0; side < 2; side++) {
          _playerControllers[side][p].text = l10n.defaultParticipantName(n);
          n++;
        }
      }
      _defaultNamesApplied = true;
    }
  }

  @override
  void dispose() {
    for (final side in _playerControllers) {
      for (final c in side) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool get _namesValid {
    for (var side = 0; side < 2; side++) {
      for (var p = 0; p < _matchType.playersPerSide; p++) {
        if (_playerControllers[side][p].text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  List<({String id, int sideIndex, int playerIndex, String label})>
  _serverOptions(AppLocalizations l10n) {
    final options =
        <({String id, int sideIndex, int playerIndex, String label})>[];
    var n = 1;
    for (var side = 0; side < 2; side++) {
      for (var p = 0; p < _matchType.playersPerSide; p++) {
        final text = _playerControllers[side][p].text.trim();
        options.add((
          id: '${side}_$p',
          sideIndex: side,
          playerIndex: p,
          label: text.isEmpty ? l10n.defaultParticipantName(n) : text,
        ));
        n++;
      }
    }
    return options;
  }

  void _onMatchTypeChanged(TennisMatchType type) {
    setState(() {
      _matchType = type;
      _initialServerId = '0_0';
    });
  }

  Future<void> _onStart() async {
    if (!_namesValid || _starting) return;
    setState(() => _starting = true);

    ScoringSide buildSide(int sideIndex, String id) {
      final players = [
        for (var p = 0; p < _matchType.playersPerSide; p++)
          _playerControllers[sideIndex][p].text.trim(),
      ];
      final name = players.join(' / ');
      return ScoringSide(id: id, name: name, players: players);
    }

    final sideA = buildSide(0, sideATennisId);
    final sideB = buildSide(1, sideBTennisId);

    final parts = _initialServerId.split('_');
    final serverSideIndex = int.parse(parts[0]);
    final serverPlayerIndex = int.parse(parts[1]);
    final service = buildTennisServiceOrder(
      matchType: _matchType,
      initialServerSideId: serverSideIndex == 0 ? sideATennisId : sideBTennisId,
      initialServerPlayerIndex: serverPlayerIndex,
    );
    final rule = buildTennisRule(
      advantageMode: _advantageMode,
      decidingSet: _decidingSet,
      service: service,
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

    final sessionId = await startTennisSession(
      ref,
      rule: rule,
      sideA: sideA,
      sideB: sideB,
    );
    if (mounted) context.pushReplacement('/score/tennis/session/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final serverOptions = _serverOptions(l10n);
    if (!serverOptions.any((o) => o.id == _initialServerId)) {
      _initialServerId = serverOptions.first.id;
    }

    Widget sectionLabel(String text) => Text(
      text,
      style: PlayTapTypography.label.copyWith(color: colors.muted),
    );

    Widget sideSection(int sideIndex) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel(l10n.tennisSideSectionLabel(sideIndex + 1)),
          const SizedBox(height: PlayTapSpacing.sm),
          for (var p = 0; p < _matchType.playersPerSide; p++) ...[
            TextField(
              controller: _playerControllers[sideIndex][p],
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
      appBar: AppBar(title: Text(l10n.tennisConfigTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PlayTapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionLabel(l10n.tennisTypeLabel),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<TennisMatchType>(
                    options: TennisMatchType.values,
                    labelBuilder: (t) => switch (t) {
                      TennisMatchType.singles => l10n.tennisTypeSingles,
                      TennisMatchType.doubles => l10n.tennisTypeDoubles,
                    },
                    value: _matchType,
                    onChanged: _onMatchTypeChanged,
                  ),
                  const SizedBox(height: PlayTapSpacing.lg),
                  sectionLabel(l10n.tennisScoringLabel),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<AdvantageMode>(
                    options: AdvantageMode.values,
                    labelBuilder: (m) => switch (m) {
                      AdvantageMode.advantage => l10n.tennisScoringAdvantage,
                      AdvantageMode.noAd => l10n.tennisScoringNoAd,
                    },
                    value: _advantageMode,
                    onChanged: (m) => setState(() => _advantageMode = m),
                  ),
                  const SizedBox(height: PlayTapSpacing.lg),
                  sectionLabel(l10n.tennisFormatLabel),
                  const SizedBox(height: PlayTapSpacing.sm),
                  Text(
                    l10n.tennisFormatBestOf3,
                    style: PlayTapTypography.body.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: PlayTapSpacing.lg),
                  sectionLabel(l10n.tennisDecidingSetLabel),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<TennisDecidingSetChoice>(
                    options: TennisDecidingSetChoice.values,
                    labelBuilder: (c) => switch (c) {
                      TennisDecidingSetChoice.tieBreakSet =>
                        l10n.tennisDecidingSetTieBreak,
                      TennisDecidingSetChoice.matchTieBreak10 =>
                        l10n.tennisDecidingSetMatchTieBreak,
                    },
                    value: _decidingSet,
                    onChanged: (c) => setState(() => _decidingSet = c),
                  ),
                  const SizedBox(height: PlayTapSpacing.xl),
                  sideSection(0),
                  sideSection(1),
                  sectionLabel(l10n.tennisInitialServerLabel),
                  const SizedBox(height: PlayTapSpacing.sm),
                  PillSelector<String>(
                    options: [for (final o in serverOptions) o.id],
                    labelBuilder: (id) =>
                        serverOptions.firstWhere((o) => o.id == id).label,
                    value: _initialServerId,
                    onChanged: (id) => setState(() => _initialServerId = id),
                  ),
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
