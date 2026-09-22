import 'package:flutter/widgets.dart';

/// The user's language choice — see docs/LOCALIZATION.md. [system] follows
/// the phone's language (falling back to English when unsupported); any
/// other value pins the app to that language regardless of the phone.
enum AppLocalePreference {
  system,
  en,
  fr,
  es,
  de,
  it,
  pt,
  ar,
  ja,
  ko,
  zhHans,
  zhHant;

  /// The [Locale] to force on [MaterialApp.locale], or `null` for [system]
  /// — which tells Flutter to resolve the locale itself via
  /// [resolveSupportedLocale].
  Locale? get explicitLocale => switch (this) {
    AppLocalePreference.system => null,
    AppLocalePreference.en => const Locale('en'),
    AppLocalePreference.fr => const Locale('fr'),
    AppLocalePreference.es => const Locale('es'),
    AppLocalePreference.de => const Locale('de'),
    AppLocalePreference.it => const Locale('it'),
    AppLocalePreference.pt => const Locale('pt'),
    AppLocalePreference.ar => const Locale('ar'),
    AppLocalePreference.ja => const Locale('ja'),
    AppLocalePreference.ko => const Locale('ko'),
    AppLocalePreference.zhHans => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    ),
    AppLocalePreference.zhHant => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
    ),
  };

  /// The stable string persisted in local storage — see `LocaleRepository`.
  /// Deliberately not `name` inline at call sites, so a future enum
  /// reordering can never silently change what's on disk.
  String get storageKey => name;

  static AppLocalePreference fromStorageKey(String? key) => values.firstWhere(
    (preference) => preference.storageKey == key,
    orElse: () => AppLocalePreference.system,
  );
}

/// Picks a supported locale for [AppLocalePreference.system]: the first
/// device locale (in the user's own preference order) whose language also
/// appears in [supportedLocales], else English — see docs/LOCALIZATION.md
/// "English fallback". Country subtags are ignored on purpose — PlayTap
/// ships one translation per language, not per region — except for
/// Chinese, which ships one translation per *script* (Simplified vs
/// Traditional): a bare "zh" is ambiguous between the two, so it's
/// resolved via [_chineseScriptFor] instead of matched directly.
Locale resolveSupportedLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocales != null) {
    for (final device in deviceLocales) {
      if (device.languageCode == 'zh') {
        final match = _matchChinese(device, supportedLocales);
        if (match != null) return match;
        continue;
      }
      for (final supported in supportedLocales) {
        if (supported.languageCode == device.languageCode) {
          return supported;
        }
      }
    }
  }
  return const Locale('en');
}

Locale? _matchChinese(Locale device, Iterable<Locale> supportedLocales) {
  final script = device.scriptCode ?? _chineseScriptFor(device.countryCode);
  for (final supported in supportedLocales) {
    if (supported.languageCode == 'zh' && supported.scriptCode == script) {
      return supported;
    }
  }
  return null;
}

/// zh-CN / zh-SG and their Simplified-script variants map to Hans;
/// zh-TW / zh-HK / zh-MO and their Traditional-script variants map to
/// Hant — see docs/LOCALIZATION.md. A bare "zh" with neither a script nor
/// one of these country codes defaults to Simplified, the more widely
/// used of the two.
String _chineseScriptFor(String? countryCode) => switch (countryCode) {
  'TW' || 'HK' || 'MO' => 'Hant',
  _ => 'Hans',
};
