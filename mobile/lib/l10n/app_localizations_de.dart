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

  @override
  String get presetPetanque => 'Pétanque';

  @override
  String get petanqueConfigTitle => 'Neue Pétanque-Partie';

  @override
  String get petanqueFormatLabel => 'Format';

  @override
  String get petanqueFormatHeadToHead => 'Einzel';

  @override
  String get petanqueFormatDoublette => 'Doublette';

  @override
  String get petanqueFormatTriplette => 'Triplette';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Team $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Teamname';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Team $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'Aufnahme $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufnahmen',
      one: '$count Aufnahme',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Letzte Aufnahme rückgängig machen';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '$amount Punkte zu $team hinzufügen';
  }

  @override
  String get abandonGameButton => 'ABBRECHEN';

  @override
  String get abandonGameDialogTitle => 'Diese Partie abbrechen?';

  @override
  String winnerAnnouncement(String name) {
    return '$name gewinnt!';
  }

  @override
  String get presetBasketball => 'Basketball';

  @override
  String get presetFootball => 'Fußball';

  @override
  String get presetFutsal => 'Futsal';

  @override
  String get basketballConfigTitle => 'Neues Basketballspiel';

  @override
  String get footballConfigTitle => 'Neues Fußballspiel';

  @override
  String get futsalConfigTitle => 'Neues Futsalspiel';

  @override
  String get teamMatchFormatLabel => 'Format';

  @override
  String get teamMatchFormatLeague => 'Liga';

  @override
  String get teamMatchFormatKnockout => 'K.-o.-Runde';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return 'Team $n';
  }

  @override
  String get teamMatchTeamNameLabel => 'Teamname';

  @override
  String teamMatchDefaultTeamName(int n) {
    return 'Team $n';
  }

  @override
  String periodLabelQuarter(int n) {
    return 'V$n';
  }

  @override
  String get periodLabelFirstHalf => '1. Halbzeit';

  @override
  String get periodLabelSecondHalf => '2. Halbzeit';

  @override
  String overtimeLabel(int n) {
    return 'Verlängerung $n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => 'Rückgängig';

  @override
  String get moreActionsButton => 'Mehr';

  @override
  String get endPeriodManuallyButton => 'Abschnitt beenden';

  @override
  String get endPeriodDialogTitle => 'Diesen Abschnitt jetzt beenden?';

  @override
  String get announceAddedTimeButton => 'Nachspielzeit';

  @override
  String get addedTimeDialogTitle => 'Nachspielzeit';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n Min.';
  }

  @override
  String get shootoutLabel => 'Elfmeterschießen';

  @override
  String get shootoutScoreButton => 'TOR';

  @override
  String get shootoutMissButton => 'VERSCHOSSEN';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team schießt';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return 'Elfmeterschießen: $scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => 'Unentschieden';
}
