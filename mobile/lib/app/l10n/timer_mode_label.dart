import '../../domain/models/timer_mode.dart';
import '../../l10n/app_localizations.dart';

/// The localized name for a Timer mode — shared by the Timer presets page,
/// the active Timer session AppBar, the Timer summary page, and History
/// (previously four separate copies of the same switch).
String timerModeLabel(AppLocalizations l10n, TimerMode? mode) => switch (mode) {
  TimerMode.stopwatch => l10n.timerModeStopwatch,
  TimerMode.countdown => l10n.timerModeCountdown,
  TimerMode.lapTimer => l10n.timerModeLaps,
  TimerMode.interval => l10n.timerModeInterval,
  null => l10n.timerSectionTitle,
};
