import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../shared/activity_category_grid.dart';
import '../shared/session_actions.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final activeSession = ref.watch(activeSessionProvider).value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: PlayTapTheme.overlayStyleOf(context),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PlayTapSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: PlayTapSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PlayTap',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings/language'),
                      icon: const Icon(Icons.language),
                      tooltip: l10n.languageSettingsTooltip,
                    ),
                  ],
                ),
                const SizedBox(height: PlayTapSpacing.xs),
                Text(
                  l10n.appTagline,
                  style: PlayTapTypography.body.copyWith(color: colors.muted),
                ),
                if (activeSession != null) ...[
                  const SizedBox(height: PlayTapSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          context.push(activeSessionRoute(activeSession)),
                      child: Text(l10n.resumeActivity),
                    ),
                  ),
                ],
                const SizedBox(height: PlayTapSpacing.xxl),
                const Expanded(child: ActivityCategoryGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
