import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum ActiveSessionChoice { resume, abandon }

/// Shared "an activity is already running" dialog — see the Phase 1B.2
/// brief section 27: the one-active-session rule is generic across
/// categories (Score and Timer), so this prompt (and its wording) must not
/// assume either one.
Future<ActiveSessionChoice?> showActiveSessionConflictDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<ActiveSessionChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.activeSessionDialogTitle),
      content: Text(l10n.activeSessionDialogContent),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ActiveSessionChoice.resume),
          child: Text(l10n.resumeActivity),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ActiveSessionChoice.abandon),
          child: Text(l10n.abandonAndStart),
        ),
      ],
    ),
  );
}
