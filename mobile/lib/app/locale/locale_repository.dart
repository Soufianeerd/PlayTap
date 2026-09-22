import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale_preference.dart';

const _localePreferenceStorageKey = 'locale_preference';

/// Persists the user's language choice — no account, no cloud, just a
/// single local key/value pair (see docs/LOCALIZATION.md). Deliberately not
/// a Drift table: this is app-level UI configuration, not sport session
/// data, so it doesn't belong in the Score/Timer/History schema.
class LocaleRepository {
  LocaleRepository() : _prefs = SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  Future<AppLocalePreference> load() async {
    final key = await _prefs.getString(_localePreferenceStorageKey);
    return AppLocalePreference.fromStorageKey(key);
  }

  Future<void> save(AppLocalePreference preference) {
    return _prefs.setString(_localePreferenceStorageKey, preference.storageKey);
  }
}
