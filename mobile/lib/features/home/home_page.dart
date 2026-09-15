import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/database_providers.dart';
import '../../app/theme/theme.dart';
import '../shared/activity_category_grid.dart';
import '../shared/session_actions.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).playTapColors;
    final activeSession = ref.watch(activeSessionProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PlayTapSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PlayTapSpacing.xxl),
              Text(
                'PlayTap',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: PlayTapSpacing.xs),
              Text(
                'Score et chrono, prêts en un tap.',
                style: PlayTapTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (activeSession != null) ...[
                const SizedBox(height: PlayTapSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        context.push(activeSessionRoute(activeSession)),
                    child: const Text('REPRENDRE L\'ACTIVITÉ'),
                  ),
                ),
              ],
              const SizedBox(height: PlayTapSpacing.xxl),
              const Expanded(child: ActivityCategoryGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
