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
}
