// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navActivities => 'Activities';

  @override
  String get navHistory => 'History';

  @override
  String get appTagline => 'Score and timer, ready in one tap.';

  @override
  String get languageSettingsTooltip => 'Language';

  @override
  String get resumeActivity => 'RESUME ACTIVITY';

  @override
  String get categoryScore => 'Keep score';

  @override
  String get categoryTimer => 'Time an activity';

  @override
  String get scoreSectionTitle => 'Score';

  @override
  String get presetFreeScore => 'Free score';

  @override
  String get timerSectionTitle => 'Timer';

  @override
  String get timerModeStopwatch => 'Stopwatch';

  @override
  String get timerModeCountdown => 'Countdown';

  @override
  String get timerModeLaps => 'Laps';

  @override
  String get timerModeInterval => 'Interval';

  @override
  String get newScoreTitle => 'New score';

  @override
  String get participantCountLabel => 'Number of participants';

  @override
  String participantNameLabel(int n) {
    return 'Participant $n name';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Player $n';
  }

  @override
  String get startButton => 'START';

  @override
  String get finishGameDialogTitle => 'Finish this game?';

  @override
  String get finishSessionDialogTitle => 'Finish this session?';

  @override
  String get cancelButton => 'CANCEL';

  @override
  String get finishButton => 'FINISH';

  @override
  String get undoLastPoint => 'Undo last point';

  @override
  String get finishGameButton => 'FINISH THE GAME';

  @override
  String addPointSemantics(String name) {
    return 'Add a point to $name';
  }

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get summaryTitle => 'Summary';

  @override
  String get lessThanAMinute => 'Less than a minute';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => 'VIEW HISTORY';

  @override
  String get activeSessionDialogTitle => 'An activity is already in progress';

  @override
  String get activeSessionDialogContent =>
      'You can resume the current activity or abandon it to start a new one.';

  @override
  String get abandonAndStart => 'ABANDON AND START';

  @override
  String get comingSoonTitle => 'Under internal construction';

  @override
  String comingSoonBody(String section) {
    return '$section is not implemented yet.';
  }

  @override
  String get comingSoonDefaultSection => 'This section';

  @override
  String get timeRemainingSemantics => 'Time remaining';

  @override
  String get timeElapsedSemantics => 'Time elapsed';

  @override
  String get pauseButtonLabel => 'PAUSE';

  @override
  String get resumeTimerButtonLabel => 'RESUME';

  @override
  String get pauseSemantics => 'Pause';

  @override
  String get resumeTimerSemantics => 'Resume';

  @override
  String get lapButton => 'LAP';

  @override
  String get recordLapSemantics => 'Record a lap';

  @override
  String get finishSessionButton => 'FINISH SESSION';

  @override
  String lapRowLabel(int number) {
    return 'Lap $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laps',
      one: '$count lap',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Quick duration';

  @override
  String get customDurationLabel => 'Custom duration (seconds)';

  @override
  String get durationValidationError => 'Choose a duration greater than 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get emptyHistoryTitle => 'No activity yet.';

  @override
  String get emptyHistorySubtitle => 'Start a score or a timer to get started.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get languagePageTitle => 'Language';

  @override
  String get languageSystemOption => 'Automatic';

  @override
  String get presetPetanque => 'Pétanque';

  @override
  String get petanqueConfigTitle => 'New pétanque game';

  @override
  String get petanqueFormatLabel => 'Format';

  @override
  String get petanqueFormatHeadToHead => 'Head-to-head';

  @override
  String get petanqueFormatDoublette => 'Doublette';

  @override
  String get petanqueFormatTriplette => 'Triplette';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Team $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Team name';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Team $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'End $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ends',
      one: '$count end',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Undo last end';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'Add $amount points to $team';
  }

  @override
  String get abandonGameButton => 'ABANDON';

  @override
  String get abandonGameDialogTitle => 'Abandon this game?';

  @override
  String winnerAnnouncement(String name) {
    return '$name wins!';
  }
}
