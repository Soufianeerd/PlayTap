// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navHome => '홈';

  @override
  String get navActivities => '활동';

  @override
  String get navHistory => '기록';

  @override
  String get appTagline => '스코어와 타이머, 탭 한 번으로 준비 완료.';

  @override
  String get languageSettingsTooltip => '언어';

  @override
  String get resumeActivity => '활동 재개';

  @override
  String get categoryScore => '점수 기록하기';

  @override
  String get categoryTimer => '시간 측정하기';

  @override
  String get scoreSectionTitle => '스코어';

  @override
  String get presetFreeScore => '자유 스코어';

  @override
  String get timerSectionTitle => '타이머';

  @override
  String get timerModeStopwatch => '스톱워치';

  @override
  String get timerModeCountdown => '카운트다운';

  @override
  String get timerModeLaps => '랩';

  @override
  String get timerModeInterval => '인터벌';

  @override
  String get newScoreTitle => '새 스코어';

  @override
  String get participantCountLabel => '참가자 수';

  @override
  String participantNameLabel(int n) {
    return '참가자 $n 이름';
  }

  @override
  String defaultParticipantName(int n) {
    return '플레이어 $n';
  }

  @override
  String get startButton => '시작';

  @override
  String get finishGameDialogTitle => '이 경기를 종료할까요?';

  @override
  String get finishSessionDialogTitle => '이 세션을 종료할까요?';

  @override
  String get cancelButton => '취소';

  @override
  String get finishButton => '종료';

  @override
  String get undoLastPoint => '마지막 포인트 취소';

  @override
  String get finishGameButton => '경기 종료';

  @override
  String addPointSemantics(String name) {
    return '$name에게 포인트 추가';
  }

  @override
  String errorPrefix(String error) {
    return '오류: $error';
  }

  @override
  String get summaryTitle => '요약';

  @override
  String get lessThanAMinute => '1분 미만';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes분',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => '기록 보기';

  @override
  String get activeSessionDialogTitle => '이미 진행 중인 활동이 있습니다';

  @override
  String get activeSessionDialogContent =>
      '진행 중인 활동을 재개하거나, 중단하고 새로 시작할 수 있습니다.';

  @override
  String get abandonAndStart => '중단하고 시작';

  @override
  String get comingSoonTitle => '내부 개발 중입니다';

  @override
  String comingSoonBody(String section) {
    return '$section은(는) 아직 구현되지 않았습니다.';
  }

  @override
  String get comingSoonDefaultSection => '이 섹션';

  @override
  String get timeRemainingSemantics => '남은 시간';

  @override
  String get timeElapsedSemantics => '경과 시간';

  @override
  String get pauseButtonLabel => '일시정지';

  @override
  String get resumeTimerButtonLabel => '재개';

  @override
  String get pauseSemantics => '일시정지';

  @override
  String get resumeTimerSemantics => '재개';

  @override
  String get lapButton => '랩';

  @override
  String get recordLapSemantics => '랩 기록';

  @override
  String get finishSessionButton => '세션 종료';

  @override
  String lapRowLabel(int number) {
    return '랩 $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '랩 $count개',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => '빠른 설정';

  @override
  String get customDurationLabel => '사용자 지정 시간(초)';

  @override
  String get durationValidationError => '0보다 큰 시간을 선택하세요.';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String get emptyHistoryTitle => '아직 활동이 없습니다.';

  @override
  String get emptyHistorySubtitle => '스코어나 타이머를 시작해 보세요.';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get languagePageTitle => '언어';

  @override
  String get languageSystemOption => '자동';

  @override
  String get presetPetanque => '페탕크';

  @override
  String get petanqueConfigTitle => '새 페탕크 게임';

  @override
  String get petanqueFormatLabel => '형식';

  @override
  String get petanqueFormatHeadToHead => '단식';

  @override
  String get petanqueFormatDoublette => '복식';

  @override
  String get petanqueFormatTriplette => '3인조';

  @override
  String petanqueTeamSectionLabel(int n) {
    return '팀 $n';
  }

  @override
  String get petanqueTeamNameLabel => '팀 이름';

  @override
  String petanqueDefaultTeamName(int n) {
    return '팀 $n';
  }

  @override
  String endNumberLabel(int n) {
    return '$n엔드';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count엔드',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => '마지막 엔드 취소';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '$team에 $amount점 추가';
  }

  @override
  String get abandonGameButton => '포기';

  @override
  String get abandonGameDialogTitle => '이 게임을 포기하시겠습니까?';

  @override
  String winnerAnnouncement(String name) {
    return '$name 승리!';
  }

  @override
  String get presetBasketball => '농가';

  @override
  String get presetFootball => '축게';

  @override
  String get presetFutsal => '푸살';

  @override
  String get basketballConfigTitle => '새 농가 게임';

  @override
  String get footballConfigTitle => '새 축게 경기';

  @override
  String get futsalConfigTitle => '새 푸살 경기';

  @override
  String get teamMatchFormatLabel => '형식';

  @override
  String get teamMatchFormatLeague => '리거';

  @override
  String get teamMatchFormatKnockout => '토대전';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return '팀 $n';
  }

  @override
  String get teamMatchTeamNameLabel => '팀 이맄';

  @override
  String teamMatchDefaultTeamName(int n) {
    return '팀 $n';
  }

  @override
  String periodLabelQuarter(int n) {
    return '$n쿼트';
  }

  @override
  String get periodLabelFirstHalf => '전반';

  @override
  String get periodLabelSecondHalf => '후반';

  @override
  String overtimeLabel(int n) {
    return '연장 $n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => '취소';

  @override
  String get moreActionsButton => '더보기';

  @override
  String get endPeriodManuallyButton => '하이플란/쿼트 종려';

  @override
  String get endPeriodDialogTitle => '지금 이 구간을 종려하겠습니까?';

  @override
  String get announceAddedTimeButton => '추가 시간';

  @override
  String get addedTimeDialogTitle => '추가 시간';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n분';
  }

  @override
  String get shootoutLabel => '승부쬨';

  @override
  String get shootoutScoreButton => '성공';

  @override
  String get shootoutMissButton => '실패';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team 쬨';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return '승부쬨: $scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => '무승부';
}
