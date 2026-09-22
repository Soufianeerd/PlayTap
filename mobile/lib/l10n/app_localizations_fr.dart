// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navActivities => 'Activités';

  @override
  String get navHistory => 'Historique';

  @override
  String get appTagline => 'Score et chrono, prêts en un tap.';

  @override
  String get languageSettingsTooltip => 'Langue';

  @override
  String get resumeActivity => 'REPRENDRE L\'ACTIVITÉ';

  @override
  String get categoryScore => 'Compter un score';

  @override
  String get categoryTimer => 'Chronométrer';

  @override
  String get scoreSectionTitle => 'Score';

  @override
  String get presetFreeScore => 'Score libre';

  @override
  String get timerSectionTitle => 'Timer';

  @override
  String get timerModeStopwatch => 'Chronomètre';

  @override
  String get timerModeCountdown => 'Compte à rebours';

  @override
  String get timerModeLaps => 'Tours';

  @override
  String get timerModeInterval => 'Intervalles';

  @override
  String get newScoreTitle => 'Nouveau score';

  @override
  String get participantCountLabel => 'Nombre de participants';

  @override
  String participantNameLabel(int n) {
    return 'Nom du participant $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Joueur $n';
  }

  @override
  String get startButton => 'COMMENCER';

  @override
  String get finishGameDialogTitle => 'Terminer cette partie ?';

  @override
  String get finishSessionDialogTitle => 'Terminer cette session ?';

  @override
  String get cancelButton => 'ANNULER';

  @override
  String get finishButton => 'TERMINER';

  @override
  String get undoLastPoint => 'Annuler le dernier point';

  @override
  String get finishGameButton => 'TERMINER LA PARTIE';

  @override
  String addPointSemantics(String name) {
    return 'Ajouter un point à $name';
  }

  @override
  String errorPrefix(String error) {
    return 'Erreur : $error';
  }

  @override
  String get summaryTitle => 'Résumé';

  @override
  String get lessThanAMinute => 'Moins d\'une minute';

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
  String get viewHistoryButton => 'VOIR L\'HISTORIQUE';

  @override
  String get activeSessionDialogTitle => 'Une activité est déjà en cours';

  @override
  String get activeSessionDialogContent =>
      'Vous pouvez reprendre l\'activité en cours ou l\'abandonner pour en démarrer une nouvelle.';

  @override
  String get abandonAndStart => 'ABANDONNER ET COMMENCER';

  @override
  String get comingSoonTitle => 'En cours de construction interne';

  @override
  String comingSoonBody(String section) {
    return '$section n\'est pas encore implémenté.';
  }

  @override
  String get comingSoonDefaultSection => 'Cette section';

  @override
  String get timeRemainingSemantics => 'Temps restant';

  @override
  String get timeElapsedSemantics => 'Temps écoulé';

  @override
  String get pauseButtonLabel => 'PAUSE';

  @override
  String get resumeTimerButtonLabel => 'REPRENDRE';

  @override
  String get pauseSemantics => 'Mettre en pause';

  @override
  String get resumeTimerSemantics => 'Reprendre';

  @override
  String get lapButton => 'TOUR';

  @override
  String get recordLapSemantics => 'Enregistrer un tour';

  @override
  String get finishSessionButton => 'TERMINER LA SESSION';

  @override
  String lapRowLabel(int number) {
    return 'Tour $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '$count tour',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Durée rapide';

  @override
  String get customDurationLabel => 'Durée personnalisée (secondes)';

  @override
  String get durationValidationError => 'Choisissez une durée supérieure à 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get emptyHistoryTitle => 'Aucune activité pour le moment.';

  @override
  String get emptyHistorySubtitle =>
      'Démarre un score ou un chronomètre pour commencer.';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get languagePageTitle => 'Langue';

  @override
  String get languageSystemOption => 'Automatique';

  @override
  String get presetPetanque => 'Pétanque';

  @override
  String get petanqueConfigTitle => 'Nouvelle partie de pétanque';

  @override
  String get petanqueFormatLabel => 'Format';

  @override
  String get petanqueFormatHeadToHead => 'Tête-à-tête';

  @override
  String get petanqueFormatDoublette => 'Doublette';

  @override
  String get petanqueFormatTriplette => 'Triplette';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Équipe $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Nom de l\'équipe';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Équipe $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'Mène $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mènes',
      one: '$count mène',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Annuler la dernière mène';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'Ajouter $amount points à $team';
  }

  @override
  String get abandonGameButton => 'ABANDONNER';

  @override
  String get abandonGameDialogTitle => 'Abandonner cette partie ?';

  @override
  String winnerAnnouncement(String name) {
    return '$name gagne !';
  }
}
