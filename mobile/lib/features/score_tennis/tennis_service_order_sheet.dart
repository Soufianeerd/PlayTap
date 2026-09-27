import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/racket_session_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../shared/pill_selector.dart';
import 'tennis_actions.dart';
import 'tennis_session_controller.dart';

/// Doubles-only, between-set (and before a Match Tie-break replacing the
/// deciding set) service-order confirmation — CLAUDE.md brief sections 7/8:
/// shown whenever `matchState.needsServiceConfiguration` is true, and
/// scoring stays gated until it's confirmed (see `active_tennis_session_
/// page.dart`, which never lets a point through while this is showing).
/// Reads `matchState.pendingServiceConfigurationSideId` to know which side
/// mechanically serves this segment's first game — never lets the user
/// pick that side themselves (ITF Rule 14, CLAUDE.md brief section 9).
class TennisServiceOrderSheet extends ConsumerStatefulWidget {
  const TennisServiceOrderSheet({
    super.key,
    required this.sessionId,
    required this.view,
  });

  final String sessionId;
  final RacketSessionSnapshot view;

  @override
  ConsumerState<TennisServiceOrderSheet> createState() =>
      _TennisServiceOrderSheetState();
}

class _TennisServiceOrderSheetState
    extends ConsumerState<TennisServiceOrderSheet> {
  late int _sideAPlayerIndex = _defaultPlayerIndex(sideATennisId);
  late int _sideBPlayerIndex = _defaultPlayerIndex(sideBTennisId);
  bool _submitting = false;

  /// Pre-selects the player who opened that side's service the last time
  /// an order was persisted (segment 0's, the only one this widget can
  /// cheaply read back) — a convenience default, never a requirement: the
  /// user can always change it before confirming (CLAUDE.md brief
  /// section 7).
  int _defaultPlayerIndex(String sideId) =>
      widget.view.racketRule.service.order
          .firstWhere((s) => s.sideId == sideId)
          .playerIndex ??
      0;

  String _playerName(String sideId, int playerIndex) {
    final side = widget.view.sides.firstWhere((s) => s.id == sideId);
    return side.players![playerIndex];
  }

  Future<void> _onContinue() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final state = widget.view.matchState;
    final startingSideId = state.pendingServiceConfigurationSideId!;
    final startingIndex = startingSideId == sideATennisId
        ? _sideAPlayerIndex
        : _sideBPlayerIndex;
    final otherIndex = startingSideId == sideATennisId
        ? _sideBPlayerIndex
        : _sideAPlayerIndex;
    final order = buildDoublesSegmentServiceOrder(
      startingSideId: startingSideId,
      startingSidePlayerIndex: startingIndex,
      otherSidePlayerIndex: otherIndex,
    );

    await ref
        .read(tennisSessionControllerProvider(widget.sessionId).notifier)
        .configureServiceOrder(
          segmentIndex: state.currentSetIndex,
          order: order,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final state = widget.view.matchState;
    final servingSideId = state.pendingServiceConfigurationSideId;
    final servingSideName = servingSideId == null
        ? ''
        : widget.view.sides.firstWhere((s) => s.id == servingSideId).name;

    Widget sectionLabel(String text) => Text(
      text,
      style: PlayTapTypography.label.copyWith(color: colors.muted),
    );

    Widget sidePicker(String sideId, int value, ValueChanged<int> onChanged) {
      final side = widget.view.sides.firstWhere((s) => s.id == sideId);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel(side.name),
          const SizedBox(height: PlayTapSpacing.sm),
          PillSelector<int>(
            options: const [0, 1],
            labelBuilder: (p) => _playerName(sideId, p),
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(height: PlayTapSpacing.lg),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PlayTapSpacing.lg,
          PlayTapSpacing.lg,
          PlayTapSpacing.lg,
          PlayTapSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.isMatchTieBreak
                  ? l10n.tennisServiceOrderMatchTieBreakTitle
                  : l10n.tennisServiceOrderSheetTitle(
                      state.currentSetIndex + 1,
                    ),
              style: PlayTapTypography.title.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PlayTapSpacing.xs),
            if (servingSideName.isNotEmpty)
              Text(
                '$servingSideName — '
                '${l10n.tennisServiceOrderServingFirstLabel}',
                style: PlayTapTypography.caption.copyWith(color: colors.muted),
              ),
            const SizedBox(height: PlayTapSpacing.lg),
            sidePicker(
              sideATennisId,
              _sideAPlayerIndex,
              (p) => setState(() => _sideAPlayerIndex = p),
            ),
            sidePicker(
              sideBTennisId,
              _sideBPlayerIndex,
              (p) => setState(() => _sideBPlayerIndex = p),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _onContinue,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.tennisContinueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
