import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale/app_locale_preference.dart';
import '../locale/locale_repository.dart';

final localeRepositoryProvider = Provider<LocaleRepository>(
  (ref) => LocaleRepository(),
);

/// The active language preference. Starts as [AppLocalePreference.system]
/// (so the first frame never blocks on disk I/O) and is replaced by the
/// persisted value, if any, once [LocaleRepository.load] resolves — see
/// docs/LOCALIZATION.md "Changement de langue immédiat".
class LocalePreferenceController extends Notifier<AppLocalePreference> {
  @override
  AppLocalePreference build() {
    _restore();
    return AppLocalePreference.system;
  }

  Future<void> _restore() async {
    final saved = await ref.read(localeRepositoryProvider).load();
    state = saved;
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    state = preference;
    await ref.read(localeRepositoryProvider).save(preference);
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceController, AppLocalePreference>(
      LocalePreferenceController.new,
    );
