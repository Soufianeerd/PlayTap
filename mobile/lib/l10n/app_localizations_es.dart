// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navActivities => 'Actividades';

  @override
  String get navHistory => 'Historial';

  @override
  String get appTagline => 'Marcador y cronómetro, listos en un toque.';

  @override
  String get languageSettingsTooltip => 'Idioma';

  @override
  String get resumeActivity => 'REANUDAR ACTIVIDAD';

  @override
  String get categoryScore => 'Llevar el marcador';

  @override
  String get categoryTimer => 'Cronometrar';

  @override
  String get scoreSectionTitle => 'Marcador';

  @override
  String get presetFreeScore => 'Marcador libre';

  @override
  String get timerSectionTitle => 'Temporizador';

  @override
  String get timerModeStopwatch => 'Cronómetro';

  @override
  String get timerModeCountdown => 'Cuenta atrás';

  @override
  String get timerModeLaps => 'Vueltas';

  @override
  String get timerModeInterval => 'Intervalos';

  @override
  String get newScoreTitle => 'Nuevo marcador';

  @override
  String get participantCountLabel => 'Número de participantes';

  @override
  String participantNameLabel(int n) {
    return 'Nombre del participante $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Jugador $n';
  }

  @override
  String get startButton => 'EMPEZAR';

  @override
  String get finishGameDialogTitle => '¿Terminar esta partida?';

  @override
  String get finishSessionDialogTitle => '¿Terminar esta sesión?';

  @override
  String get cancelButton => 'CANCELAR';

  @override
  String get finishButton => 'TERMINAR';

  @override
  String get undoLastPoint => 'Deshacer el último punto';

  @override
  String get finishGameButton => 'TERMINAR LA PARTIDA';

  @override
  String addPointSemantics(String name) {
    return 'Añadir un punto a $name';
  }

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get summaryTitle => 'Resumen';

  @override
  String get lessThanAMinute => 'Menos de un minuto';

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
  String get viewHistoryButton => 'VER HISTORIAL';

  @override
  String get activeSessionDialogTitle => 'Ya hay una actividad en curso';

  @override
  String get activeSessionDialogContent =>
      'Puedes reanudar la actividad en curso o abandonarla para empezar una nueva.';

  @override
  String get abandonAndStart => 'ABANDONAR Y EMPEZAR';

  @override
  String get comingSoonTitle => 'En construcción interna';

  @override
  String comingSoonBody(String section) {
    return '$section aún no está implementado.';
  }

  @override
  String get comingSoonDefaultSection => 'Esta sección';

  @override
  String get timeRemainingSemantics => 'Tiempo restante';

  @override
  String get timeElapsedSemantics => 'Tiempo transcurrido';

  @override
  String get pauseButtonLabel => 'PAUSA';

  @override
  String get resumeTimerButtonLabel => 'REANUDAR';

  @override
  String get pauseSemantics => 'Pausar';

  @override
  String get resumeTimerSemantics => 'Reanudar';

  @override
  String get lapButton => 'VUELTA';

  @override
  String get recordLapSemantics => 'Registrar una vuelta';

  @override
  String get finishSessionButton => 'TERMINAR SESIÓN';

  @override
  String lapRowLabel(int number) {
    return 'Vuelta $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vueltas',
      one: '$count vuelta',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Duración rápida';

  @override
  String get customDurationLabel => 'Duración personalizada (segundos)';

  @override
  String get durationValidationError => 'Elige una duración mayor que 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get emptyHistoryTitle => 'Todavía no hay actividad.';

  @override
  String get emptyHistorySubtitle =>
      'Inicia un marcador o un cronómetro para empezar.';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get languagePageTitle => 'Idioma';

  @override
  String get languageSystemOption => 'Automático';

  @override
  String get presetTennis => 'Tenis';

  @override
  String get tennisConfigTitle => 'Nuevo partido de tenis';

  @override
  String get tennisTypeLabel => 'Tipo';

  @override
  String get tennisTypeSingles => 'Individual';

  @override
  String get tennisTypeDoubles => 'Dobles';

  @override
  String get tennisScoringLabel => 'Puntuación';

  @override
  String get tennisScoringAdvantage => 'Ventaja';

  @override
  String get tennisScoringNoAd => 'Sin ventaja';

  @override
  String get tennisFormatLabel => 'Formato';

  @override
  String get tennisFormatBestOf3 => 'Al mejor de 3';

  @override
  String get tennisDecidingSetLabel => 'Set decisivo';

  @override
  String get tennisDecidingSetTieBreak => 'Set con tie-break';

  @override
  String get tennisDecidingSetMatchTieBreak => 'Tie-break de partido a 10';

  @override
  String tennisSideSectionLabel(int n) {
    return 'Lado $n';
  }

  @override
  String get tennisInitialServerLabel => 'Primer sacador';

  @override
  String tennisSetLabel(int n) {
    return 'Set $n';
  }

  @override
  String get tennisSetsRowLabel => 'Sets';

  @override
  String get tennisGamesRowLabel => 'Juegos';

  @override
  String get tennisPointsRowLabel => 'Puntos';

  @override
  String tennisServerLabel(String name) {
    return 'Saque: $name';
  }

  @override
  String get tennisChangeEndsLabel => 'Cambio de lado';

  @override
  String get tennisUndoLastPoint => 'Deshacer último punto';

  @override
  String get tennisDeuceLabel => 'Iguales';

  @override
  String get tennisAdvantageLabel => 'Ventaja';

  @override
  String tennisPointSemantics(String name) {
    return 'Punto para $name';
  }

  @override
  String get tennisMatchTieBreakShort => 'Tie-break de partido';

  @override
  String get presetPetanque => 'Petanca';

  @override
  String get petanqueConfigTitle => 'Nueva partida de petanca';

  @override
  String get petanqueFormatLabel => 'Formato';

  @override
  String get petanqueFormatHeadToHead => 'Individual';

  @override
  String get petanqueFormatDoublette => 'Dupla';

  @override
  String get petanqueFormatTriplette => 'Tripleta';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Equipo $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Nombre del equipo';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Equipo $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'Manga $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangas',
      one: '$count manga',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Deshacer última manga';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'Añadir $amount puntos a $team';
  }

  @override
  String get abandonGameButton => 'ABANDONAR';

  @override
  String get abandonGameDialogTitle => '¿Abandonar esta partida?';

  @override
  String winnerAnnouncement(String name) {
    return '¡$name gana!';
  }

  @override
  String get presetBasketball => 'Baloncesto';

  @override
  String get presetFootball => 'Fútbol';

  @override
  String get presetFutsal => 'Fútbol sala';

  @override
  String get basketballConfigTitle => 'Nuevo partido de baloncesto';

  @override
  String get footballConfigTitle => 'Nuevo partido de fútbol';

  @override
  String get futsalConfigTitle => 'Nuevo partido de fútbol sala';

  @override
  String get teamMatchFormatLabel => 'Formato';

  @override
  String get teamMatchFormatLeague => 'Liga';

  @override
  String get teamMatchFormatKnockout => 'Eliminatoria';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return 'Equipo $n';
  }

  @override
  String get teamMatchTeamNameLabel => 'Nombre del equipo';

  @override
  String teamMatchDefaultTeamName(int n) {
    return 'Equipo $n';
  }

  @override
  String periodLabelQuarter(int n) {
    return 'C$n';
  }

  @override
  String get periodLabelFirstHalf => '1.ª parte';

  @override
  String get periodLabelSecondHalf => '2.ª parte';

  @override
  String overtimeLabel(int n) {
    return 'Prórroga $n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => 'Deshacer';

  @override
  String get moreActionsButton => 'Más';

  @override
  String get endPeriodManuallyButton => 'Terminar periodo';

  @override
  String get endPeriodDialogTitle => '¿Terminar este periodo ahora?';

  @override
  String get announceAddedTimeButton => 'Tiempo añadido';

  @override
  String get addedTimeDialogTitle => 'Tiempo añadido';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n min';
  }

  @override
  String get shootoutLabel => 'Tanda de penaltis';

  @override
  String get shootoutScoreButton => 'GOL';

  @override
  String get shootoutMissButton => 'FALLADO';

  @override
  String shootoutNextKickerLabel(String team) {
    return 'Tira $team';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return 'Tanda de penaltis: $scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => 'Empate';

  @override
  String get shotClockLabel => 'Reloj de posesión';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => 'Faltas de equipo';

  @override
  String get bonusIndicatorLabel => 'BONUS';

  @override
  String addTeamFoulSemantics(String team) {
    return 'Añadir una falta de equipo a $team';
  }

  @override
  String get timeoutsLabel => 'Tiempos muertos';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team: $count tiempos muertos restantes';
  }
}
