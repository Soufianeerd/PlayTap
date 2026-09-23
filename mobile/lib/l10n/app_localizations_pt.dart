// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navHome => 'Início';

  @override
  String get navActivities => 'Atividades';

  @override
  String get navHistory => 'Histórico';

  @override
  String get appTagline => 'Placar e cronômetro, prontos em um toque.';

  @override
  String get languageSettingsTooltip => 'Idioma';

  @override
  String get resumeActivity => 'RETOMAR ATIVIDADE';

  @override
  String get categoryScore => 'Contar pontos';

  @override
  String get categoryTimer => 'Cronometrar';

  @override
  String get scoreSectionTitle => 'Placar';

  @override
  String get presetFreeScore => 'Placar livre';

  @override
  String get timerSectionTitle => 'Timer';

  @override
  String get timerModeStopwatch => 'Cronômetro';

  @override
  String get timerModeCountdown => 'Contagem regressiva';

  @override
  String get timerModeLaps => 'Voltas';

  @override
  String get timerModeInterval => 'Intervalo';

  @override
  String get newScoreTitle => 'Novo placar';

  @override
  String get participantCountLabel => 'Número de participantes';

  @override
  String participantNameLabel(int n) {
    return 'Nome do participante $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'Jogador $n';
  }

  @override
  String get startButton => 'COMEÇAR';

  @override
  String get finishGameDialogTitle => 'Encerrar esta partida?';

  @override
  String get finishSessionDialogTitle => 'Encerrar esta sessão?';

  @override
  String get cancelButton => 'CANCELAR';

  @override
  String get finishButton => 'ENCERRAR';

  @override
  String get undoLastPoint => 'Desfazer o último ponto';

  @override
  String get finishGameButton => 'ENCERRAR A PARTIDA';

  @override
  String addPointSemantics(String name) {
    return 'Adicionar um ponto a $name';
  }

  @override
  String errorPrefix(String error) {
    return 'Erro: $error';
  }

  @override
  String get summaryTitle => 'Resumo';

  @override
  String get lessThanAMinute => 'Menos de um minuto';

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
  String get viewHistoryButton => 'VER HISTÓRICO';

  @override
  String get activeSessionDialogTitle => 'Já há uma atividade em andamento';

  @override
  String get activeSessionDialogContent =>
      'Você pode retomar a atividade em andamento ou abandoná-la para iniciar uma nova.';

  @override
  String get abandonAndStart => 'ABANDONAR E COMEÇAR';

  @override
  String get comingSoonTitle => 'Em construção interna';

  @override
  String comingSoonBody(String section) {
    return '$section ainda não foi implementado.';
  }

  @override
  String get comingSoonDefaultSection => 'Esta seção';

  @override
  String get timeRemainingSemantics => 'Tempo restante';

  @override
  String get timeElapsedSemantics => 'Tempo decorrido';

  @override
  String get pauseButtonLabel => 'PAUSAR';

  @override
  String get resumeTimerButtonLabel => 'RETOMAR';

  @override
  String get pauseSemantics => 'Pausar';

  @override
  String get resumeTimerSemantics => 'Retomar';

  @override
  String get lapButton => 'VOLTA';

  @override
  String get recordLapSemantics => 'Registrar uma volta';

  @override
  String get finishSessionButton => 'ENCERRAR SESSÃO';

  @override
  String lapRowLabel(int number) {
    return 'Volta $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voltas',
      one: '$count volta',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'Duração rápida';

  @override
  String get customDurationLabel => 'Duração personalizada (segundos)';

  @override
  String get durationValidationError => 'Escolha uma duração maior que 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get emptyHistoryTitle => 'Ainda não há atividade.';

  @override
  String get emptyHistorySubtitle =>
      'Inicie um placar ou um timer para começar.';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get languagePageTitle => 'Idioma';

  @override
  String get languageSystemOption => 'Automático';

  @override
  String get presetPetanque => 'Petanca';

  @override
  String get petanqueConfigTitle => 'Nova partida de petanca';

  @override
  String get petanqueFormatLabel => 'Formato';

  @override
  String get petanqueFormatHeadToHead => 'Individual';

  @override
  String get petanqueFormatDoublette => 'Dupla';

  @override
  String get petanqueFormatTriplette => 'Trinca';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'Equipe $n';
  }

  @override
  String get petanqueTeamNameLabel => 'Nome da equipe';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'Equipe $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'Rodada $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rodadas',
      one: '$count rodada',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'Desfazer última rodada';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'Adicionar $amount pontos a $team';
  }

  @override
  String get abandonGameButton => 'ABANDONAR';

  @override
  String get abandonGameDialogTitle => 'Abandonar esta partida?';

  @override
  String winnerAnnouncement(String name) {
    return '$name vence!';
  }

  @override
  String get presetBasketball => 'Basquetebol';

  @override
  String get presetFootball => 'Futebol';

  @override
  String get presetFutsal => 'Futsal';

  @override
  String get basketballConfigTitle => 'Novo jogo de basquetebol';

  @override
  String get footballConfigTitle => 'Novo jogo de futebol';

  @override
  String get futsalConfigTitle => 'Novo jogo de futsal';

  @override
  String get teamMatchFormatLabel => 'Formato';

  @override
  String get teamMatchFormatLeague => 'Liga';

  @override
  String get teamMatchFormatKnockout => 'Eliminatória';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return 'Equipe $n';
  }

  @override
  String get teamMatchTeamNameLabel => 'Nome da equipe';

  @override
  String teamMatchDefaultTeamName(int n) {
    return 'Equipe $n';
  }

  @override
  String periodLabelQuarter(int n) {
    return 'Q$n';
  }

  @override
  String get periodLabelFirstHalf => '1º tempo';

  @override
  String get periodLabelSecondHalf => '2º tempo';

  @override
  String overtimeLabel(int n) {
    return 'Prórroga $n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => 'Desfazer';

  @override
  String get moreActionsButton => 'Mais';

  @override
  String get endPeriodManuallyButton => 'Terminar período';

  @override
  String get endPeriodDialogTitle => 'Terminar este período agora?';

  @override
  String get announceAddedTimeButton => 'Tempo adicional';

  @override
  String get addedTimeDialogTitle => 'Tempo adicional';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n min';
  }

  @override
  String get shootoutLabel => 'Disûte de pênaltis';

  @override
  String get shootoutScoreButton => 'MARCOU';

  @override
  String get shootoutMissButton => 'PERDEU';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team cobra';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return 'Disûte de pênaltis: $scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => 'Empate';

  @override
  String get shotClockLabel => 'Relógio de posse';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => 'Faltas de equipe';

  @override
  String get bonusIndicatorLabel => 'BONUS';

  @override
  String addTeamFoulSemantics(String team) {
    return 'Adicionar falta de equipe a $team';
  }

  @override
  String get timeoutsLabel => 'Tempos técnicos';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team: $count tempos técnicos restantes';
  }
}
