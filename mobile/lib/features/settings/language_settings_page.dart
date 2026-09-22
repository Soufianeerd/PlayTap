import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale/app_locale_preference.dart';
import '../../app/providers/locale_providers.dart';
import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Each language's own name, in its own script — shown regardless of the
/// app's current language, per convention (a French speaker still finds
/// "English" in the list when PlayTap is in French). Not part of the ARB
/// files: these are endonyms, not something to translate.
const _languageEndonyms = {
  AppLocalePreference.en: 'English',
  AppLocalePreference.fr: 'Français',
  AppLocalePreference.es: 'Español',
  AppLocalePreference.de: 'Deutsch',
  AppLocalePreference.it: 'Italiano',
  AppLocalePreference.pt: 'Português',
  AppLocalePreference.ar: 'العربية',
  AppLocalePreference.ja: '日本語',
  AppLocalePreference.ko: '한국어',
  AppLocalePreference.zhHans: '简体中文',
  AppLocalePreference.zhHant: '繁體中文',
};

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).playTapColors;
    final current = ref.watch(localePreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languagePageTitle)),
      body: RadioGroup<AppLocalePreference>(
        groupValue: current,
        onChanged: (value) {
          if (value != null) {
            ref.read(localePreferenceProvider.notifier).setPreference(value);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.sm),
          children: [
            for (final preference in AppLocalePreference.values)
              RadioListTile<AppLocalePreference>(
                value: preference,
                activeColor: colors.primary,
                title: Text(
                  preference == AppLocalePreference.system
                      ? l10n.languageSystemOption
                      : _languageEndonyms[preference]!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
