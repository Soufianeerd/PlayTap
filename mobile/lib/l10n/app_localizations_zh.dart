// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首页';

  @override
  String get navActivities => '活动';

  @override
  String get navHistory => '历史记录';

  @override
  String get appTagline => '计分和计时,一键就绪。';

  @override
  String get languageSettingsTooltip => '语言';

  @override
  String get resumeActivity => '继续活动';

  @override
  String get categoryScore => '记录比分';

  @override
  String get categoryTimer => '计时';

  @override
  String get scoreSectionTitle => '比分';

  @override
  String get presetFreeScore => '自由比分';

  @override
  String get timerSectionTitle => '计时器';

  @override
  String get timerModeStopwatch => '秒表';

  @override
  String get timerModeCountdown => '倒计时';

  @override
  String get timerModeLaps => '圈数';

  @override
  String get timerModeInterval => '间歇';

  @override
  String get newScoreTitle => '新建比分';

  @override
  String get participantCountLabel => '参与人数';

  @override
  String participantNameLabel(int n) {
    return '参与者$n的名称';
  }

  @override
  String defaultParticipantName(int n) {
    return '玩家$n';
  }

  @override
  String get startButton => '开始';

  @override
  String get finishGameDialogTitle => '结束本局比赛?';

  @override
  String get finishSessionDialogTitle => '结束本次会话?';

  @override
  String get cancelButton => '取消';

  @override
  String get finishButton => '结束';

  @override
  String get undoLastPoint => '撤销上一分';

  @override
  String get finishGameButton => '结束比赛';

  @override
  String addPointSemantics(String name) {
    return '为$name加一分';
  }

  @override
  String errorPrefix(String error) {
    return '错误: $error';
  }

  @override
  String get summaryTitle => '摘要';

  @override
  String get lessThanAMinute => '不到一分钟';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分钟',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => '查看历史记录';

  @override
  String get activeSessionDialogTitle => '已有一个进行中的活动';

  @override
  String get activeSessionDialogContent => '你可以继续当前的活动,或放弃它以开始新的活动。';

  @override
  String get abandonAndStart => '放弃并开始';

  @override
  String get comingSoonTitle => '内部开发中';

  @override
  String comingSoonBody(String section) {
    return '$section尚未实现。';
  }

  @override
  String get comingSoonDefaultSection => '此部分';

  @override
  String get timeRemainingSemantics => '剩余时间';

  @override
  String get timeElapsedSemantics => '已用时间';

  @override
  String get pauseButtonLabel => '暂停';

  @override
  String get resumeTimerButtonLabel => '继续';

  @override
  String get pauseSemantics => '暂停';

  @override
  String get resumeTimerSemantics => '继续';

  @override
  String get lapButton => '圈';

  @override
  String get recordLapSemantics => '记录一圈';

  @override
  String get finishSessionButton => '结束会话';

  @override
  String lapRowLabel(int number) {
    return '第$number圈';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count圈',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => '快速时长';

  @override
  String get customDurationLabel => '自定义时长(秒)';

  @override
  String get durationValidationError => '请选择大于0的时长。';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get emptyHistoryTitle => '暂无活动。';

  @override
  String get emptyHistorySubtitle => '开始一次计分或计时吧。';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get languagePageTitle => '语言';

  @override
  String get languageSystemOption => '自动';

  @override
  String get presetTennis => '网球';

  @override
  String get tennisConfigTitle => '新网球比赛';

  @override
  String get tennisTypeLabel => '类型';

  @override
  String get tennisTypeSingles => '单打';

  @override
  String get tennisTypeDoubles => '双打';

  @override
  String get tennisScoringLabel => '计分方式';

  @override
  String get tennisScoringAdvantage => '占先制';

  @override
  String get tennisScoringNoAd => '无占先制';

  @override
  String get tennisFormatLabel => '赛制';

  @override
  String get tennisFormatBestOf3 => '三盘两胜';

  @override
  String get tennisDecidingSetLabel => '决胜盘';

  @override
  String get tennisDecidingSetTieBreak => '抢七决胜盘';

  @override
  String get tennisDecidingSetMatchTieBreak => '10分制胜局';

  @override
  String tennisSideSectionLabel(int n) {
    return '$n方';
  }

  @override
  String get tennisInitialServerLabel => '首个发球方';

  @override
  String tennisSetLabel(int n) {
    return '第$n盘';
  }

  @override
  String get tennisSetsRowLabel => '盘数';

  @override
  String get tennisGamesRowLabel => '局数';

  @override
  String get tennisPointsRowLabel => '分数';

  @override
  String tennisServerLabel(String name) {
    return '发球方：$name';
  }

  @override
  String get tennisChangeEndsLabel => '交换场地';

  @override
  String get tennisUndoLastPoint => '撤销上一分';

  @override
  String get tennisDeuceLabel => '平分';

  @override
  String get tennisAdvantageLabel => '占先';

  @override
  String tennisPointSemantics(String name) {
    return '$name得分';
  }

  @override
  String get tennisMatchTieBreakShort => '制胜局';

  @override
  String get presetPetanque => '滚球';

  @override
  String get petanqueConfigTitle => '新建滚球比赛';

  @override
  String get petanqueFormatLabel => '赛制';

  @override
  String get petanqueFormatHeadToHead => '单打';

  @override
  String get petanqueFormatDoublette => '双打';

  @override
  String get petanqueFormatTriplette => '三人赛';

  @override
  String petanqueTeamSectionLabel(int n) {
    return '队伍$n';
  }

  @override
  String get petanqueTeamNameLabel => '队伍名称';

  @override
  String petanqueDefaultTeamName(int n) {
    return '队伍$n';
  }

  @override
  String endNumberLabel(int n) {
    return '第$n局';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count局',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => '撤销上一局';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '为$team加$amount分';
  }

  @override
  String get abandonGameButton => '放弃';

  @override
  String get abandonGameDialogTitle => '放弃本场比赛？';

  @override
  String winnerAnnouncement(String name) {
    return '$name获胜！';
  }

  @override
  String get presetBasketball => '篮球';

  @override
  String get presetFootball => '足球';

  @override
  String get presetFutsal => '室内五人制足球';

  @override
  String get basketballConfigTitle => '新篮球比赛';

  @override
  String get footballConfigTitle => '新足球比赛';

  @override
  String get futsalConfigTitle => '新五人制足球比赛';

  @override
  String get teamMatchFormatLabel => '赛制';

  @override
  String get teamMatchFormatLeague => '联赛';

  @override
  String get teamMatchFormatKnockout => '知出赛';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return '队伍$n';
  }

  @override
  String get teamMatchTeamNameLabel => '队伍名称';

  @override
  String teamMatchDefaultTeamName(int n) {
    return '队伍$n';
  }

  @override
  String periodLabelQuarter(int n) {
    return '第$n节';
  }

  @override
  String get periodLabelFirstHalf => '上半场';

  @override
  String get periodLabelSecondHalf => '下半场';

  @override
  String overtimeLabel(int n) {
    return '加时$n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => '撤销';

  @override
  String get moreActionsButton => '更多';

  @override
  String get endPeriodManuallyButton => '结束本节';

  @override
  String get endPeriodDialogTitle => '现在结束本节吗？';

  @override
  String get announceAddedTimeButton => '伤添补时';

  @override
  String get addedTimeDialogTitle => '伤添补时';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n分钟';
  }

  @override
  String get shootoutLabel => '点球大战';

  @override
  String get shootoutScoreButton => '命中';

  @override
  String get shootoutMissButton => '未命中';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team下一个主射';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return '点球大战：$scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => '平局';

  @override
  String get shotClockLabel => '进攻时钟';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => '团队犯规';

  @override
  String get bonusIndicatorLabel => '罚球';

  @override
  String addTeamFoulSemantics(String team) {
    return '为$team增加一次团队犯规';
  }

  @override
  String get timeoutsLabel => '暂停';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team：剩余$count次暂停';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get navHome => '首页';

  @override
  String get navActivities => '活动';

  @override
  String get navHistory => '历史记录';

  @override
  String get appTagline => '计分和计时,一键就绪。';

  @override
  String get languageSettingsTooltip => '语言';

  @override
  String get resumeActivity => '继续活动';

  @override
  String get categoryScore => '记录比分';

  @override
  String get categoryTimer => '计时';

  @override
  String get scoreSectionTitle => '比分';

  @override
  String get presetFreeScore => '自由比分';

  @override
  String get timerSectionTitle => '计时器';

  @override
  String get timerModeStopwatch => '秒表';

  @override
  String get timerModeCountdown => '倒计时';

  @override
  String get timerModeLaps => '圈数';

  @override
  String get timerModeInterval => '间歇';

  @override
  String get newScoreTitle => '新建比分';

  @override
  String get participantCountLabel => '参与人数';

  @override
  String participantNameLabel(int n) {
    return '参与者$n的名称';
  }

  @override
  String defaultParticipantName(int n) {
    return '玩家$n';
  }

  @override
  String get startButton => '开始';

  @override
  String get finishGameDialogTitle => '结束本局比赛?';

  @override
  String get finishSessionDialogTitle => '结束本次会话?';

  @override
  String get cancelButton => '取消';

  @override
  String get finishButton => '结束';

  @override
  String get undoLastPoint => '撤销上一分';

  @override
  String get finishGameButton => '结束比赛';

  @override
  String addPointSemantics(String name) {
    return '为$name加一分';
  }

  @override
  String errorPrefix(String error) {
    return '错误: $error';
  }

  @override
  String get summaryTitle => '摘要';

  @override
  String get lessThanAMinute => '不到一分钟';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分钟',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => '查看历史记录';

  @override
  String get activeSessionDialogTitle => '已有一个进行中的活动';

  @override
  String get activeSessionDialogContent => '你可以继续当前的活动,或放弃它以开始新的活动。';

  @override
  String get abandonAndStart => '放弃并开始';

  @override
  String get comingSoonTitle => '内部开发中';

  @override
  String comingSoonBody(String section) {
    return '$section尚未实现。';
  }

  @override
  String get comingSoonDefaultSection => '此部分';

  @override
  String get timeRemainingSemantics => '剩余时间';

  @override
  String get timeElapsedSemantics => '已用时间';

  @override
  String get pauseButtonLabel => '暂停';

  @override
  String get resumeTimerButtonLabel => '继续';

  @override
  String get pauseSemantics => '暂停';

  @override
  String get resumeTimerSemantics => '继续';

  @override
  String get lapButton => '圈';

  @override
  String get recordLapSemantics => '记录一圈';

  @override
  String get finishSessionButton => '结束会话';

  @override
  String lapRowLabel(int number) {
    return '第$number圈';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count圈',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => '快速时长';

  @override
  String get customDurationLabel => '自定义时长(秒)';

  @override
  String get durationValidationError => '请选择大于0的时长。';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get emptyHistoryTitle => '暂无活动。';

  @override
  String get emptyHistorySubtitle => '开始一次计分或计时吧。';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get languagePageTitle => '语言';

  @override
  String get languageSystemOption => '自动';

  @override
  String get presetTennis => '网球';

  @override
  String get tennisConfigTitle => '新网球比赛';

  @override
  String get tennisTypeLabel => '类型';

  @override
  String get tennisTypeSingles => '单打';

  @override
  String get tennisTypeDoubles => '双打';

  @override
  String get tennisScoringLabel => '计分方式';

  @override
  String get tennisScoringAdvantage => '占先制';

  @override
  String get tennisScoringNoAd => '无占先制';

  @override
  String get tennisFormatLabel => '赛制';

  @override
  String get tennisFormatBestOf3 => '三盘两胜';

  @override
  String get tennisDecidingSetLabel => '决胜盘';

  @override
  String get tennisDecidingSetTieBreak => '抢七决胜盘';

  @override
  String get tennisDecidingSetMatchTieBreak => '10分制胜局';

  @override
  String tennisSideSectionLabel(int n) {
    return '$n方';
  }

  @override
  String get tennisInitialServerLabel => '首个发球方';

  @override
  String tennisSetLabel(int n) {
    return '第$n盘';
  }

  @override
  String get tennisSetsRowLabel => '盘数';

  @override
  String get tennisGamesRowLabel => '局数';

  @override
  String get tennisPointsRowLabel => '分数';

  @override
  String tennisServerLabel(String name) {
    return '发球方：$name';
  }

  @override
  String get tennisChangeEndsLabel => '交换场地';

  @override
  String get tennisUndoLastPoint => '撤销上一分';

  @override
  String get tennisDeuceLabel => '平分';

  @override
  String get tennisAdvantageLabel => '占先';

  @override
  String tennisPointSemantics(String name) {
    return '$name得分';
  }

  @override
  String get tennisMatchTieBreakShort => '制胜局';

  @override
  String get presetPetanque => '滚球';

  @override
  String get petanqueConfigTitle => '新建滚球比赛';

  @override
  String get petanqueFormatLabel => '赛制';

  @override
  String get petanqueFormatHeadToHead => '单打';

  @override
  String get petanqueFormatDoublette => '双打';

  @override
  String get petanqueFormatTriplette => '三人赛';

  @override
  String petanqueTeamSectionLabel(int n) {
    return '队伍$n';
  }

  @override
  String get petanqueTeamNameLabel => '队伍名称';

  @override
  String petanqueDefaultTeamName(int n) {
    return '队伍$n';
  }

  @override
  String endNumberLabel(int n) {
    return '第$n局';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count局',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => '撤销上一局';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '为$team加$amount分';
  }

  @override
  String get abandonGameButton => '放弃';

  @override
  String get abandonGameDialogTitle => '放弃本场比赛？';

  @override
  String winnerAnnouncement(String name) {
    return '$name获胜！';
  }

  @override
  String get presetBasketball => '篮球';

  @override
  String get presetFootball => '足球';

  @override
  String get presetFutsal => '室内五人制足球';

  @override
  String get basketballConfigTitle => '新篮球比赛';

  @override
  String get footballConfigTitle => '新足球比赛';

  @override
  String get futsalConfigTitle => '新五人制足球比赛';

  @override
  String get teamMatchFormatLabel => '赛制';

  @override
  String get teamMatchFormatLeague => '联赛';

  @override
  String get teamMatchFormatKnockout => '知出赛';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return '队伍$n';
  }

  @override
  String get teamMatchTeamNameLabel => '队伍名称';

  @override
  String teamMatchDefaultTeamName(int n) {
    return '队伍$n';
  }

  @override
  String periodLabelQuarter(int n) {
    return '第$n节';
  }

  @override
  String get periodLabelFirstHalf => '上半场';

  @override
  String get periodLabelSecondHalf => '下半场';

  @override
  String overtimeLabel(int n) {
    return '加时$n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => '撤销';

  @override
  String get moreActionsButton => '更多';

  @override
  String get endPeriodManuallyButton => '结束本节';

  @override
  String get endPeriodDialogTitle => '现在结束本节吗？';

  @override
  String get announceAddedTimeButton => '伤添补时';

  @override
  String get addedTimeDialogTitle => '伤添补时';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n分钟';
  }

  @override
  String get shootoutLabel => '点球大战';

  @override
  String get shootoutScoreButton => '命中';

  @override
  String get shootoutMissButton => '未命中';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team下一个主射';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return '点球大战：$scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => '平局';

  @override
  String get shotClockLabel => '进攻时钟';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => '团队犯规';

  @override
  String get bonusIndicatorLabel => '罚球';

  @override
  String addTeamFoulSemantics(String team) {
    return '为$team增加一次团队犯规';
  }

  @override
  String get timeoutsLabel => '暂停';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team：剩余$count次暂停';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get navHome => '首頁';

  @override
  String get navActivities => '活動';

  @override
  String get navHistory => '記錄';

  @override
  String get appTagline => '計分與計時,一鍵就緒。';

  @override
  String get languageSettingsTooltip => '語言';

  @override
  String get resumeActivity => '繼續活動';

  @override
  String get categoryScore => '記錄比分';

  @override
  String get categoryTimer => '計時';

  @override
  String get scoreSectionTitle => '比分';

  @override
  String get presetFreeScore => '自由比分';

  @override
  String get timerSectionTitle => '計時器';

  @override
  String get timerModeStopwatch => '碼表';

  @override
  String get timerModeCountdown => '倒數計時';

  @override
  String get timerModeLaps => '圈數';

  @override
  String get timerModeInterval => '間歇';

  @override
  String get newScoreTitle => '新增比分';

  @override
  String get participantCountLabel => '參與人數';

  @override
  String participantNameLabel(int n) {
    return '參與者$n的名稱';
  }

  @override
  String defaultParticipantName(int n) {
    return '玩家$n';
  }

  @override
  String get startButton => '開始';

  @override
  String get finishGameDialogTitle => '結束本局比賽?';

  @override
  String get finishSessionDialogTitle => '結束本次工作階段?';

  @override
  String get cancelButton => '取消';

  @override
  String get finishButton => '結束';

  @override
  String get undoLastPoint => '復原上一分';

  @override
  String get finishGameButton => '結束比賽';

  @override
  String addPointSemantics(String name) {
    return '為$name加一分';
  }

  @override
  String errorPrefix(String error) {
    return '錯誤: $error';
  }

  @override
  String get summaryTitle => '摘要';

  @override
  String get lessThanAMinute => '不到一分鐘';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分鐘',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => '查看記錄';

  @override
  String get activeSessionDialogTitle => '已有一項活動正在進行';

  @override
  String get activeSessionDialogContent => '你可以繼續目前的活動,或放棄它以開始新的活動。';

  @override
  String get abandonAndStart => '放棄並開始';

  @override
  String get comingSoonTitle => '內部開發中';

  @override
  String comingSoonBody(String section) {
    return '$section尚未實作。';
  }

  @override
  String get comingSoonDefaultSection => '此部分';

  @override
  String get timeRemainingSemantics => '剩餘時間';

  @override
  String get timeElapsedSemantics => '經過時間';

  @override
  String get pauseButtonLabel => '暫停';

  @override
  String get resumeTimerButtonLabel => '繼續';

  @override
  String get pauseSemantics => '暫停';

  @override
  String get resumeTimerSemantics => '繼續';

  @override
  String get lapButton => '圈';

  @override
  String get recordLapSemantics => '記錄一圈';

  @override
  String get finishSessionButton => '結束工作階段';

  @override
  String lapRowLabel(int number) {
    return '第$number圈';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count圈',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => '快速時長';

  @override
  String get customDurationLabel => '自訂時長(秒)';

  @override
  String get durationValidationError => '請選擇大於0的時長。';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get emptyHistoryTitle => '尚無活動。';

  @override
  String get emptyHistorySubtitle => '開始一次計分或計時吧。';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get languagePageTitle => '語言';

  @override
  String get languageSystemOption => '自動';

  @override
  String get presetTennis => '網球';

  @override
  String get tennisConfigTitle => '新網球比賽';

  @override
  String get tennisTypeLabel => '類型';

  @override
  String get tennisTypeSingles => '單打';

  @override
  String get tennisTypeDoubles => '雙打';

  @override
  String get tennisScoringLabel => '計分方式';

  @override
  String get tennisScoringAdvantage => '佔先制';

  @override
  String get tennisScoringNoAd => '無佔先制';

  @override
  String get tennisFormatLabel => '賽制';

  @override
  String get tennisFormatBestOf3 => '三盤兩勝';

  @override
  String get tennisDecidingSetLabel => '決勝盤';

  @override
  String get tennisDecidingSetTieBreak => '搶七決勝盤';

  @override
  String get tennisDecidingSetMatchTieBreak => '10分制勝局';

  @override
  String tennisSideSectionLabel(int n) {
    return '$n方';
  }

  @override
  String get tennisInitialServerLabel => '首個發球方';

  @override
  String tennisSetLabel(int n) {
    return '第$n盤';
  }

  @override
  String get tennisSetsRowLabel => '盤數';

  @override
  String get tennisGamesRowLabel => '局數';

  @override
  String get tennisPointsRowLabel => '分數';

  @override
  String tennisServerLabel(String name) {
    return '發球方：$name';
  }

  @override
  String get tennisChangeEndsLabel => '交換場地';

  @override
  String get tennisUndoLastPoint => '撤銷上一分';

  @override
  String get tennisDeuceLabel => '平分';

  @override
  String get tennisAdvantageLabel => '佔先';

  @override
  String tennisPointSemantics(String name) {
    return '$name得分';
  }

  @override
  String get tennisMatchTieBreakShort => '制勝局';

  @override
  String get presetPetanque => '滾球';

  @override
  String get petanqueConfigTitle => '新建滾球比賽';

  @override
  String get petanqueFormatLabel => '賽制';

  @override
  String get petanqueFormatHeadToHead => '單打';

  @override
  String get petanqueFormatDoublette => '雙打';

  @override
  String get petanqueFormatTriplette => '三人賽';

  @override
  String petanqueTeamSectionLabel(int n) {
    return '隊伍$n';
  }

  @override
  String get petanqueTeamNameLabel => '隊伍名稱';

  @override
  String petanqueDefaultTeamName(int n) {
    return '隊伍$n';
  }

  @override
  String endNumberLabel(int n) {
    return '第$n局';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count局',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => '復原上一局';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '為$team加$amount分';
  }

  @override
  String get abandonGameButton => '放棄';

  @override
  String get abandonGameDialogTitle => '放棄本場比賽？';

  @override
  String winnerAnnouncement(String name) {
    return '$name獲勝！';
  }

  @override
  String get presetBasketball => '籃球';

  @override
  String get presetFootball => '足球';

  @override
  String get presetFutsal => '室內五人制足球';

  @override
  String get basketballConfigTitle => '新籃球比賽';

  @override
  String get footballConfigTitle => '新足球比賽';

  @override
  String get futsalConfigTitle => '新五人制足球比賽';

  @override
  String get teamMatchFormatLabel => '賽制';

  @override
  String get teamMatchFormatLeague => '聯賽';

  @override
  String get teamMatchFormatKnockout => '知出賽';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return '隊伍$n';
  }

  @override
  String get teamMatchTeamNameLabel => '隊伍名稱';

  @override
  String teamMatchDefaultTeamName(int n) {
    return '隊伍$n';
  }

  @override
  String periodLabelQuarter(int n) {
    return '第$n節';
  }

  @override
  String get periodLabelFirstHalf => '上半場';

  @override
  String get periodLabelSecondHalf => '下半場';

  @override
  String overtimeLabel(int n) {
    return '加時$n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => '撤銷';

  @override
  String get moreActionsButton => '更多';

  @override
  String get endPeriodManuallyButton => '結束本節';

  @override
  String get endPeriodDialogTitle => '現在結束本節嗎？';

  @override
  String get announceAddedTimeButton => '傷添補時';

  @override
  String get addedTimeDialogTitle => '傷添補時';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n分鐘';
  }

  @override
  String get shootoutLabel => '點球大戰';

  @override
  String get shootoutScoreButton => '命中';

  @override
  String get shootoutMissButton => '未命中';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$team下一個主射';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return '點球大戰：$scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => '平手';

  @override
  String get shotClockLabel => '進攻時鐘';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => '團隊犯規';

  @override
  String get bonusIndicatorLabel => '罰球';

  @override
  String addTeamFoulSemantics(String team) {
    return '為$team增加一次團隊犯規';
  }

  @override
  String get timeoutsLabel => '暫停';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team：剩餘$count次暫停';
  }
}
