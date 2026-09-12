import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/session_category.dart';
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
    (i) => TextEditingController(text: 'Joueur ${i + 1}'),
  );
  bool _starting = false;

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
        .getActiveSession(SessionCategory.score);

    if (!mounted) return;

    if (existing != null) {
      final choice = await showDialog<_ActiveSessionChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Une partie est déjà en cours'),
          content: const Text(
            'Vous pouvez reprendre la partie en cours ou l\'abandonner pour en démarrer une nouvelle.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ActiveSessionChoice.resume),
              child: const Text('REPRENDRE LA PARTIE'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ActiveSessionChoice.abandon),
              child: const Text('ABANDONNER ET COMMENCER'),
            ),
          ],
        ),
      );

      if (choice == null) {
        setState(() => _starting = false);
        return;
      }
      if (choice == _ActiveSessionChoice.resume) {
        if (mounted) {
          context.pushReplacement('/score/free/session/${existing.id}');
        }
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

    return Scaffold(
      appBar: AppBar(title: const Text('Score libre')),
      body: Padding(
        padding: const EdgeInsets.all(PlayTapSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre de participants',
              style: PlayTapTypography.label.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: PlayTapSpacing.sm),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {_sideCount},
              onSelectionChanged: (selection) =>
                  setState(() => _sideCount = selection.first),
            ),
            const SizedBox(height: PlayTapSpacing.xl),
            for (var i = 0; i < _sideCount; i++) ...[
              TextField(
                controller: _controllers[i],
                decoration: InputDecoration(
                  labelText: 'Nom du participant ${i + 1}',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PlayTapSpacing.md),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _namesValid && !_starting ? _onStart : null,
                child: _starting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('COMMENCER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActiveSessionChoice { resume, abandon }
