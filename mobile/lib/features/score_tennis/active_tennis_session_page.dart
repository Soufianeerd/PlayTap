import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/engines/racket_labels.dart';
import '../../domain/models/racket_session_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../shared/session_actions.dart';
import 'tennis_actions.dart';
import 'tennis_service_order_sheet.dart';
import 'tennis_session_controller.dart';

class ActiveTennisSessionPage extends ConsumerStatefulWidget {
  const ActiveTennisSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ActiveTennisSessionPage> createState() =>
      _ActiveTennisSessionPageState();
}

class _ActiveTennisSessionPageState
    extends ConsumerState<ActiveTennisSessionPage> {
  /// Guards against opening the sheet twice (e.g. two rebuilds racing
  /// through their post-frame callbacks before the first `showModalBottomSheet`
  /// call has actually mounted it) — mirrors the controller's own
  /// `_mutationInFlight` guard, applied here to a UI action instead of a
  /// persisted event (CLAUDE.md brief section 25).
  bool _serviceOrderSheetOpen = false;

  /// Shown whenever `matchState.needsServiceConfiguration` is true —
  /// on entering a new doubles set/Match Tie-break, and again on cold
  /// start/recovery if the app was killed before it was confirmed (CLAUDE.md
  /// brief sections 8/11). Not dismissible: scoring stays blocked (see
  /// `_TennisBody`'s tap zones) until a valid choice is confirmed.
  Future<void> _maybeShowServiceOrderSheet(RacketSessionSnapshot view) async {
    if (_serviceOrderSheetOpen || !view.matchState.needsServiceConfiguration) {
      return;
    }
    _serviceOrderSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) =>
          TennisServiceOrderSheet(sessionId: widget.sessionId, view: view),
    );
    _serviceOrderSheetOpen = false;
  }

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
    await abandonSession(ref, widget.sessionId);
    if (context.mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).playTapColors;
    final sessionId = widget.sessionId;

    ref.listen<AsyncValue<RacketSessionSnapshot>>(
      tennisSessionControllerProvider(sessionId),
      (previous, next) {
        final wasComplete = previous?.value?.matchState.matchComplete ?? false;
        final isComplete = next.value?.matchState.matchComplete ?? false;
        if (!wasComplete && isComplete) {
          context.pushReplacement('/score/tennis/summary/$sessionId');
        }
      },
    );

    final asyncView = ref.watch(tennisSessionControllerProvider(sessionId));

    final view = asyncView.value;
    if (view != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowServiceOrderSheet(view);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.presetTennis),
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
        data: (view) => _TennisBody(sessionId: sessionId, view: view),
      ),
    );
  }
}

class _TennisBody extends ConsumerWidget {
  const _TennisBody({required this.sessionId, required this.view});

  final String sessionId;
  final RacketSessionSnapshot view;

  String _serverName(AppLocalizations l10n) {
    final slot = view.racketRule.service.order.firstWhere(
      (s) => s.id == view.matchState.currentServerSlotId,
    );
    final side = view.sides.firstWhere((s) => s.id == slot.sideId);
    if (slot.playerIndex == null) return side.name;
    return side.players![slot.playerIndex!];
  }

  String _pointsDisplay(AppLocalizations l10n, String sideId) {
    final state = view.matchState;
    if (state.isTieBreak || state.isMatchTieBreak) {
      return '${state.tieBreakPoints[sideId] ?? 0}';
    }
    final labels = RacketLabels.gamePointLabels(
      points: state.currentGamePoints,
      sideIds: view.racketRule.sideIds,
      mode: view.racketRule.gameScoring.advantageMode,
    );
    final label = labels[sideId]!;
    return switch (label.kind) {
      RacketPointLabelKind.numeric => label.value!,
      RacketPointLabelKind.deuce => l10n.tennisDeuceLabel,
      RacketPointLabelKind.advantage => l10n.tennisAdvantageLabel,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final sideA = view.sides.firstWhere((s) => s.id == sideATennisId);
    final sideB = view.sides.firstWhere((s) => s.id == sideBTennisId);
    final state = view.matchState;

    void addPoint(String sideId) => ref
        .read(tennisSessionControllerProvider(sessionId).notifier)
        .addPoint(sideId);

    // Blocks scoring while a doubles service-order confirmation is
    // pending (CLAUDE.md brief section 8) — the sheet is already showing
    // (see `_ActiveTennisSessionPageState._maybeShowServiceOrderSheet`),
    // but the tap zones underneath it must not accept a point that would
    // race ahead of it, e.g. via a stray tap next to the (non-dismissible,
    // but not full-screen) sheet.
    final scoringBlocked = state.needsServiceConfiguration;

    return Column(
      children: [
        _UndoBar(
          enabled: view.isUndoAvailable,
          onTap: () => ref
              .read(tennisSessionControllerProvider(sessionId).notifier)
              .undoLast(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlayTapSpacing.lg,
            vertical: PlayTapSpacing.sm,
          ),
          child: Column(
            children: [
              Text(
                l10n.tennisSetLabel(state.currentSetIndex + 1),
                style: PlayTapTypography.label.copyWith(color: colors.muted),
              ),
              const SizedBox(height: PlayTapSpacing.sm),
              _ScoreRow(
                rowLabel: l10n.tennisSetsRowLabel,
                valueA: '${state.setsWon[sideATennisId] ?? 0}',
                valueB: '${state.setsWon[sideBTennisId] ?? 0}',
              ),
              if (!state.isMatchTieBreak)
                _ScoreRow(
                  rowLabel: l10n.tennisGamesRowLabel,
                  valueA: '${state.gamesWonInCurrentSet[sideATennisId] ?? 0}',
                  valueB: '${state.gamesWonInCurrentSet[sideBTennisId] ?? 0}',
                ),
              _ScoreRow(
                rowLabel: l10n.tennisPointsRowLabel,
                valueA: _pointsDisplay(l10n, sideATennisId),
                valueB: _pointsDisplay(l10n, sideBTennisId),
                emphasize: true,
              ),
              const SizedBox(height: PlayTapSpacing.xs),
              Semantics(
                label: l10n.tennisServerLabel(_serverName(l10n)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: colors.primary),
                    const SizedBox(width: PlayTapSpacing.xs),
                    Text(
                      l10n.tennisServerLabel(_serverName(l10n)),
                      style: PlayTapTypography.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.changeEndsDue)
                Padding(
                  padding: const EdgeInsets.only(top: PlayTapSpacing.xs),
                  child: Text(
                    l10n.tennisChangeEndsLabel,
                    style: PlayTapTypography.caption.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _BigTapZone(
                  name: sideA.name,
                  background: colors.primary,
                  foreground: colors.onPrimary,
                  semanticsLabel: l10n.tennisPointSemantics(sideA.name),
                  onTap: scoringBlocked ? null : () => addPoint(sideATennisId),
                ),
              ),
              Expanded(
                child: _BigTapZone(
                  name: sideB.name,
                  background: colors.accent,
                  foreground: colors.onAccent,
                  semanticsLabel: l10n.tennisPointSemantics(sideB.name),
                  onTap: scoringBlocked ? null : () => addPoint(sideBTennisId),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rowLabel,
    required this.valueA,
    required this.valueB,
    this.emphasize = false,
  });

  final String rowLabel;
  final String valueA;
  final String valueB;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final valueStyle = emphasize
        ? PlayTapTypography.title.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w800,
          )
        : PlayTapTypography.body.copyWith(color: colors.foreground);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              rowLabel,
              style: PlayTapTypography.caption.copyWith(color: colors.muted),
            ),
          ),
          Expanded(
            child: Text(valueA, textAlign: TextAlign.center, style: valueStyle),
          ),
          Expanded(
            child: Text(valueB, textAlign: TextAlign.center, style: valueStyle),
          ),
        ],
      ),
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
                AppLocalizations.of(context)!.tennisUndoLastPoint,
                style: PlayTapTypography.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A whole-panel tap target — "regarder, taper, continuer à jouer" (CLAUDE.md
/// brief section 19/20): no precise `+1` button, the entire colored side is
/// the target, with a light haptic and immediate visual feedback, no
/// confirmation dialog.
class _BigTapZone extends StatelessWidget {
  const _BigTapZone({
    required this.name,
    required this.background,
    required this.foreground,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String name;
  final Color background;
  final Color foreground;
  final String semanticsLabel;

  /// Null disables the zone entirely (no ripple, no haptic) — used while
  /// `matchState.needsServiceConfiguration` blocks scoring (CLAUDE.md
  /// brief section 8).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: PlayTapTypography.title.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
