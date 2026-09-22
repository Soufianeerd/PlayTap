// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navHome => 'Start';

  @override
  String get navActivities => 'Aktivitäten';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get appTagline => 'Punktestand und Timer, startklar mit einem Tipp.';

  @override
  String get languageSettingsTooltip => 'Sprache';

  @override
  String get resumeActivity => 'AKTIVITÄT FORTSETZEN';

  @override
  String get categoryScore => 'Punkte zählen';

  @override
  String get categoryTimer => 'Zeit stoppen';

  @override
  String get scoreSectionTitle => 'Punktestand';

  @override
  String get presetFreeScore => 'Freier Punktestand';

  @override
  String get timerSectionTitle => 'Timer';

  @override
  String get timerModeStopwatch => 'Stoppuhr';

  @override
  String get timerModeCountdown => 'Countdown';

  @override
  String get timerModeLaps => 'Runden';

  @override
  String get timerModeInterval => 'Intervall';

  @override
  String get newScoreTitle => 'Neuer Punktestand';

  @override
  String get participantCountLabel => 'Anzahl der Teilnehmer';

  @override
  String participantNameLabel(int n) {
    return 'Name von Teilnehmer $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Spieler $n';
  }

  @override
  String get startButton => 'STARTEN';

  @override
  String get finishGameDialogTitle => 'Diese Partie beenden?';

  @override
  String get finishSessionDialogTitle => 'Diese Sitzung beenden?';

  @override
  String get cancelButton => 'ABBRECHEN';

  @override
  String get finishButton => 'BEENDEN';

  @override
  String get undoLastPoint => 'Letzten Punkt rückgängig machen';

  @override
  String get finishGameButton => 'PARTIE BEENDEN';

  @override
  String addPointSemantics(String name) {
    return 'Einen Punkt für $name hinzufügen';
  }

  @override
  String errorPrefix(String error) {
    return 'Fehler: $error';
  }

  @override
  String get summaryTitle => 'Zusammenfassung';

  @override
  String get lessThanAMinute => 'Weniger als eine Minute';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Min.',
      one: '$minutes Min.',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => 'VERLAUF ANZEIGEN';

  @override
  String get activeSessionDialogTitle => 'Es läuft bereits eine Aktivität';

  @override
  String get activeSessionDialogContent =>
      'Du kannst die laufende Aktivität fortsetzen oder sie abbrechen, um eine neue zu starten.';

  @override
  String get abandonAndStart => 'ABBRECHEN UND STARTEN';

  @override
  String get comingSoonTitle => 'Wird intern noch entwickelt';

  @override
  String comingSoonBody(String section) {
    return '$section ist noch nicht implementiert.';
  }

  @override
  String get comingSoonDefaultSection => 'Dieser Bereich';

  @override
  String get timeRemainingSemantics => 'Verbleibende Zeit';

  @override
  String get timeElapsedSemantics => 'Verstrichene Zeit';

  @override
  String get pauseButtonLabel => 'PAUSE';

  @override
  String get resumeTimerButtonLabel => 'FORTSETZEN';

  @override
  String get pauseSemantics => 'Pausieren';

  @override
  String get resumeTimerSemantics => 'Fortsetzen';

  @override
  String get lapButton => 'RUNDE';

  @override
  String get recordLapSemantics => 'Eine Runde aufzeichnen';

  @override
  String get finishSessionButton => 'SITZUNG BEENDEN';

  @override
  String lapRowLabel(int number) {
    return 'Runde $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '$count Runde',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Schnelle Dauer';

  @override
  String get customDurationLabel => 'Individuelle Dauer (Sekunden)';

  @override
  String get durationValidationError => 'Wähle eine Dauer größer als 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get emptyHistoryTitle => 'Noch keine Aktivität.';

  @override
  String get emptyHistorySubtitle =>
      'Starte einen Punktestand oder einen Timer, um loszulegen.';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get languagePageTitle => 'Sprache';

  @override
  String get languageSystemOption => 'Automatisch';
}
