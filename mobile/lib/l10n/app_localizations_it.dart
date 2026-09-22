// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navActivities => 'Attività';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get appTagline => 'Punteggio e timer, pronti con un tocco.';

  @override
  String get languageSettingsTooltip => 'Lingua';

  @override
  String get resumeActivity => 'RIPRENDI ATTIVITÀ';

  @override
  String get categoryScore => 'Tieni il punteggio';

  @override
  String get categoryTimer => 'Cronometra';

  @override
  String get scoreSectionTitle => 'Punteggio';

  @override
  String get presetFreeScore => 'Punteggio libero';

  @override
  String get timerSectionTitle => 'Timer';

  @override
  String get timerModeStopwatch => 'Cronometro';

  @override
  String get timerModeCountdown => 'Conto alla rovescia';

  @override
  String get timerModeLaps => 'Giri';

  @override
  String get timerModeInterval => 'Intervallo';

  @override
  String get newScoreTitle => 'Nuovo punteggio';

  @override
  String get participantCountLabel => 'Numero di partecipanti';

  @override
  String participantNameLabel(int n) {
    return 'Nome del partecipante $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Giocatore $n';
  }

  @override
  String get startButton => 'INIZIA';

  @override
  String get finishGameDialogTitle => 'Terminare questa partita?';

  @override
  String get finishSessionDialogTitle => 'Terminare questa sessione?';

  @override
  String get cancelButton => 'ANNULLA';

  @override
  String get finishButton => 'TERMINA';

  @override
  String get undoLastPoint => 'Annulla l\'ultimo punto';

  @override
  String get finishGameButton => 'TERMINA LA PARTITA';

  @override
  String addPointSemantics(String name) {
    return 'Aggiungi un punto a $name';
  }

  @override
  String errorPrefix(String error) {
    return 'Errore: $error';
  }

  @override
  String get summaryTitle => 'Riepilogo';

  @override
  String get lessThanAMinute => 'Meno di un minuto';

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
  String get viewHistoryButton => 'VEDI CRONOLOGIA';

  @override
  String get activeSessionDialogTitle => 'Un\'attività è già in corso';

  @override
  String get activeSessionDialogContent =>
      'Puoi riprendere l\'attività in corso oppure abbandonarla per iniziarne una nuova.';

  @override
  String get abandonAndStart => 'ABBANDONA E INIZIA';

  @override
  String get comingSoonTitle => 'In costruzione interna';

  @override
  String comingSoonBody(String section) {
    return '$section non è ancora implementato.';
  }

  @override
  String get comingSoonDefaultSection => 'Questa sezione';

  @override
  String get timeRemainingSemantics => 'Tempo rimanente';

  @override
  String get timeElapsedSemantics => 'Tempo trascorso';

  @override
  String get pauseButtonLabel => 'PAUSA';

  @override
  String get resumeTimerButtonLabel => 'RIPRENDI';

  @override
  String get pauseSemantics => 'Metti in pausa';

  @override
  String get resumeTimerSemantics => 'Riprendi';

  @override
  String get lapButton => 'GIRO';

  @override
  String get recordLapSemantics => 'Registra un giro';

  @override
  String get finishSessionButton => 'TERMINA SESSIONE';

  @override
  String lapRowLabel(int number) {
    return 'Giro $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giri',
      one: '$count giro',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Durata rapida';

  @override
  String get customDurationLabel => 'Durata personalizzata (secondi)';

  @override
  String get durationValidationError => 'Scegli una durata maggiore di 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get emptyHistoryTitle => 'Ancora nessuna attività.';

  @override
  String get emptyHistorySubtitle =>
      'Avvia un punteggio o un timer per iniziare.';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get languagePageTitle => 'Lingua';

  @override
  String get languageSystemOption => 'Automatica';

  @override
  String get presetPetanque => 'Petanque';

  @override
  String get petanqueConfigTitle => 'Nuova partita di petanque';

  @override
  String get petanqueFormatLabel => 'Formato';

  @override
  String get petanqueFormatHeadToHead => 'Singolo';

  @override
  String get petanqueFormatDoublette => 'Doppietta';

  @override
  String get petanqueFormatTriplette => 'Tripletta';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Squadra $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Nome squadra';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Squadra $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'Turno $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turni',
      one: '$count turno',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Annulla ultimo turno';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'Aggiungi $amount punti a $team';
  }

  @override
  String get abandonGameButton => 'ABBANDONA';

  @override
  String get abandonGameDialogTitle => 'Abbandonare questa partita?';

  @override
  String winnerAnnouncement(String name) {
    return '$name vince!';
  }
}
