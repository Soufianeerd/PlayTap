import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/scoring_side.dart';
import 'free_score_session_controller.dart';

class ActiveFreeScoreSessionPage extends ConsumerWidget {
  const ActiveFreeScoreSessionPage({super.key, required this.sessionId});

  final String sessionId;

  Future<void> _confirmComplete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer cette partie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('TERMINER'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(freeScoreSessionControllerProvider(sessionId).notifier)
        .complete();
    if (context.mounted) {
      context.pushReplacement('/score/free/summary/$sessionId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncView = ref.watch(freeScoreSessionControllerProvider(sessionId));
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score libre'),
        actions: [
          asyncView.maybeWhen(
            data: (view) => Tooltip(
              message: 'Annuler le dernier point',
              child: IconButton(
                icon: const Icon(Icons.undo),
                onPressed: view.isUndoAvailable
                    ? () => ref
                          .read(
                            freeScoreSessionControllerProvider(
                              sessionId,
                            ).notifier,
                          )
                          .undoLast()
                    : null,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Erreur : $e', style: TextStyle(color: colors.danger)),
        ),
        data: (view) => Column(
          children: [
            Expanded(
              child: _ScoreLayout(
                sides: view.sides,
                scores: view.scoreState.scores,
                onTapSide: (sideId) => ref
                    .read(
                      freeScoreSessionControllerProvider(sessionId).notifier,
                    )
                    .addPoint(sideId),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(PlayTapSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmComplete(context, ref),
                    child: const Text('TERMINER LA PARTIE'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreLayout extends StatelessWidget {
  const _ScoreLayout({
    required this.sides,
    required this.scores,
    required this.onTapSide,
  });

  final List<ScoringSide> sides;
  final Map<String, int> scores;
  final ValueChanged<String> onTapSide;

  @override
  Widget build(BuildContext context) {
    Widget tile(int index, {bool nameFirst = true}) {
      final side = sides[index];
      return _ScoreTile(
        name: side.name,
        score: scores[side.id] ?? 0,
        nameFirst: nameFirst,
        alternate: index.isOdd,
        onTap: () => onTapSide(side.id),
      );
    }

    switch (sides.length) {
      case 2:
        return Column(
          children: [
            Expanded(child: tile(0)),
            const Divider(height: 1),
            Expanded(child: tile(1, nameFirst: false)),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(child: tile(0)),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(1)),
                  const VerticalDivider(width: 1),
                  Expanded(child: tile(2)),
                ],
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(0)),
                  const VerticalDivider(width: 1),
                  Expanded(child: tile(1)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(2)),
                  const VerticalDivider(width: 1),
                  Expanded(child: tile(3)),
                ],
              ),
            ),
          ],
        );
      default:
        throw StateError('Unsupported side count: ${sides.length}');
    }
  }
}

class _ScoreTile extends StatefulWidget {
  const _ScoreTile({
    required this.name,
    required this.score,
    required this.onTap,
    this.nameFirst = true,
    this.alternate = false,
  });

  final String name;
  final int score;
  final VoidCallback onTap;
  final bool nameFirst;
  final bool alternate;

  @override
  State<_ScoreTile> createState() => _ScoreTileState();
}

class _ScoreTileState extends State<_ScoreTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    lowerBound: 1.0,
    upperBound: 1.08,
  )..value = 1.0;

  @override
  void didUpdateWidget(_ScoreTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      _pulse.forward().then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final nameText = Text(
      widget.name,
      style: PlayTapTypography.title.copyWith(color: colors.textSecondary),
    );
    final scoreText = ScaleTransition(
      scale: _pulse,
      child: Text(
        '${widget.score}',
        style: PlayTapTypography.scoreDisplay.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Ajouter un point à ${widget.name}',
      child: Material(
        color: widget.alternate ? colors.surfaceVariant : colors.surface,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.nameFirst
                  ? [
                      nameText,
                      const SizedBox(height: PlayTapSpacing.sm),
                      scoreText,
                    ]
                  : [
                      scoreText,
                      const SizedBox(height: PlayTapSpacing.sm),
                      nameText,
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
