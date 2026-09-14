import 'package:flutter/material.dart';

enum ActiveSessionChoice { resume, abandon }

/// Shared "an activity is already running" dialog — see the Phase 1B.2
/// brief section 27: the one-active-session rule is generic across
/// categories (Score and Timer), so this prompt (and its wording) must not
/// assume either one.
Future<ActiveSessionChoice?> showActiveSessionConflictDialog(
  BuildContext context,
) {
  return showDialog<ActiveSessionChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Une activité est déjà en cours'),
      content: const Text(
        'Vous pouvez reprendre l\'activité en cours ou l\'abandonner pour en démarrer une nouvelle.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ActiveSessionChoice.resume),
          child: const Text('REPRENDRE L\'ACTIVITÉ'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ActiveSessionChoice.abandon),
          child: const Text('ABANDONNER ET COMMENCER'),
        ),
      ],
    ),
  );
}
