// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navHome => 'ホーム';

  @override
  String get navActivities => 'アクティビティ';

  @override
  String get navHistory => '履歴';

  @override
  String get appTagline => 'スコアとタイマー、ワンタップですぐに。';

  @override
  String get languageSettingsTooltip => '言語';

  @override
  String get resumeActivity => 'アクティビティを再開';

  @override
  String get categoryScore => 'スコアをつける';

  @override
  String get categoryTimer => 'タイムを計る';

  @override
  String get scoreSectionTitle => 'スコア';

  @override
  String get presetFreeScore => 'フリースコア';

  @override
  String get timerSectionTitle => 'タイマー';

  @override
  String get timerModeStopwatch => 'ストップウォッチ';

  @override
  String get timerModeCountdown => 'カウントダウン';

  @override
  String get timerModeLaps => 'ラップ';

  @override
  String get timerModeInterval => 'インターバル';

  @override
  String get newScoreTitle => '新しいスコア';

  @override
  String get participantCountLabel => '参加人数';

  @override
  String participantNameLabel(int n) {
    return '参加者$nの名前';
  }

  @override
  String defaultParticipantName(int n) {
    return 'プレイヤー$n';
  }

  @override
  String get startButton => '開始';

  @override
  String get finishGameDialogTitle => 'この試合を終了しますか?';

  @override
  String get finishSessionDialogTitle => 'このセッションを終了しますか?';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get finishButton => '終了';

  @override
  String get undoLastPoint => '直前のポイントを取り消す';

  @override
  String get finishGameButton => '試合を終了';

  @override
  String addPointSemantics(String name) {
    return '$nameにポイントを追加';
  }

  @override
  String errorPrefix(String error) {
    return 'エラー: $error';
  }

  @override
  String get summaryTitle => 'サマリー';

  @override
  String get lessThanAMinute => '1分未満';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => '履歴を見る';

  @override
  String get activeSessionDialogTitle => 'すでにアクティビティが進行中です';

  @override
  String get activeSessionDialogContent =>
      '進行中のアクティビティを再開するか、中止して新しく始めることができます。';

  @override
  String get abandonAndStart => '中止して新規開始';

  @override
  String get comingSoonTitle => '現在開発中です';

  @override
  String comingSoonBody(String section) {
    return '$sectionはまだ実装されていません。';
  }

  @override
  String get comingSoonDefaultSection => 'このセクション';

  @override
  String get timeRemainingSemantics => '残り時間';

  @override
  String get timeElapsedSemantics => '経過時間';

  @override
  String get pauseButtonLabel => '一時停止';

  @override
  String get resumeTimerButtonLabel => '再開';

  @override
  String get pauseSemantics => '一時停止';

  @override
  String get resumeTimerSemantics => '再開';

  @override
  String get lapButton => 'ラップ';

  @override
  String get recordLapSemantics => 'ラップを記録';

  @override
  String get finishSessionButton => 'セッションを終了';

  @override
  String lapRowLabel(int number) {
    return 'ラップ$number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countラップ',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'クイック設定';

  @override
  String get customDurationLabel => 'カスタム時間(秒)';

  @override
  String get durationValidationError => '0より大きい時間を選んでください。';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get emptyHistoryTitle => 'まだアクティビティがありません。';

  @override
  String get emptyHistorySubtitle => 'スコアやタイマーを開始してみましょう。';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get languagePageTitle => '言語';

  @override
  String get languageSystemOption => '自動';

  @override
  String get presetTennis => 'テニス';

  @override
  String get tennisConfigTitle => '新しいテニスの試合';

  @override
  String get tennisTypeLabel => '種目';

  @override
  String get tennisTypeSingles => 'シングルス';

  @override
  String get tennisTypeDoubles => 'ダブルス';

  @override
  String get tennisScoringLabel => 'スコア方式';

  @override
  String get tennisScoringAdvantage => 'アドバンテージ';

  @override
  String get tennisScoringNoAd => 'ノーアド';

  @override
  String get tennisFormatLabel => 'フォーマット';

  @override
  String get tennisFormatBestOf3 => '3セットマッチ';

  @override
  String get tennisDecidingSetLabel => '最終セット';

  @override
  String get tennisDecidingSetTieBreak => 'タイブレーク方式';

  @override
  String get tennisDecidingSetMatchTieBreak => '10ポイントマッチタイブレーク';

  @override
  String tennisSideSectionLabel(int n) {
    return 'サイド$n';
  }

  @override
  String get tennisInitialServerLabel => '最初のサーバー';

  @override
  String tennisSetLabel(int n) {
    return 'セット$n';
  }

  @override
  String get tennisSetsRowLabel => 'セット';

  @override
  String get tennisGamesRowLabel => 'ゲーム';

  @override
  String get tennisPointsRowLabel => 'ポイント';

  @override
  String tennisServerLabel(String name) {
    return 'サーブ: $name';
  }

  @override
  String get tennisChangeEndsLabel => 'コートチェンジ';

  @override
  String get tennisUndoLastPoint => '直前のポイントを取り消す';

  @override
  String get tennisDeuceLabel => 'デュース';

  @override
  String get tennisAdvantageLabel => 'アドバンテージ';

  @override
  String tennisPointSemantics(String name) {
    return '$nameのポイント';
  }

  @override
  String get tennisMatchTieBreakShort => 'マッチタイブレーク';

  @override
  String get presetPetanque => 'ペタンク';

  @override
  String get petanqueConfigTitle => '新しいペタンクゲーム';

  @override
  String get petanqueFormatLabel => 'フォーマット';

  @override
  String get petanqueFormatHeadToHead => 'シングル';

  @override
  String get petanqueFormatDoublette => 'ダブル';

  @override
  String get petanqueFormatTriplette => 'トリプル';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'チーム$n';
  }

  @override
  String get petanqueTeamNameLabel => 'チーム名';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'チーム$n';
  }

  @override
  String endNumberLabel(int n) {
    return '第$nエンド';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countエンド',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => '直前のエンドを取り消す';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return '$teamに$amount点を追加';
  }

  @override
  String get abandonGameButton => '中断';

  @override
  String get abandonGameDialogTitle => 'このゲームを中断しますか?';

  @override
  String winnerAnnouncement(String name) {
    return '$nameの勝利!';
  }

  @override
  String get presetBasketball => 'バスケットフットボール';

  @override
  String get presetFootball => 'サッカー';

  @override
  String get presetFutsal => 'フットサル';

  @override
  String get basketballConfigTitle => '新しいバスケットフットボールの試合';

  @override
  String get footballConfigTitle => '新しいサッカーの試合';

  @override
  String get futsalConfigTitle => '新しいフットサルの試合';

  @override
  String get teamMatchFormatLabel => '形式';

  @override
  String get teamMatchFormatLeague => 'リーグ';

  @override
  String get teamMatchFormatKnockout => 'ノックアドト';

  @override
  String teamMatchTeamSectionLabel(int n) {
    return 'チーム$n';
  }

  @override
  String get teamMatchTeamNameLabel => 'チーム名';

  @override
  String teamMatchDefaultTeamName(int n) {
    return 'チーム$n';
  }

  @override
  String periodLabelQuarter(int n) {
    return 'Q$n';
  }

  @override
  String get periodLabelFirstHalf => '前半';

  @override
  String get periodLabelSecondHalf => '後半';

  @override
  String overtimeLabel(int n) {
    return '延長$n';
  }

  @override
  String addedTimeBadge(int minutes) {
    return '+$minutes';
  }

  @override
  String get undoLastActionLabel => '元に戻す';

  @override
  String get moreActionsButton => 'もっと';

  @override
  String get endPeriodManuallyButton => 'ピリオドを終了';

  @override
  String get endPeriodDialogTitle => 'このピリオドを今終了しますか？';

  @override
  String get announceAddedTimeButton => 'アディショナレタイム';

  @override
  String get addedTimeDialogTitle => 'アディショナレタイム';

  @override
  String addedTimeMinutesOption(int n) {
    return '+$n分';
  }

  @override
  String get shootoutLabel => 'PK戦';

  @override
  String get shootoutScoreButton => '成功';

  @override
  String get shootoutMissButton => '失敗';

  @override
  String shootoutNextKickerLabel(String team) {
    return '$teamのキッカー';
  }

  @override
  String shootoutScoreLine(int scoreA, int scoreB) {
    return 'PK戦：$scoreA – $scoreB';
  }

  @override
  String get matchDrawResultLabel => 'ドロー';

  @override
  String get shotClockLabel => 'ショットクロック';

  @override
  String get shotClock24Button => '24';

  @override
  String get shotClock14Button => '14';

  @override
  String get teamFoulsLabel => 'チームファウル';

  @override
  String get bonusIndicatorLabel => 'ボーナス';

  @override
  String addTeamFoulSemantics(String team) {
    return '$teamにチームファウルを追加';
  }

  @override
  String get timeoutsLabel => 'タイムアウト';

  @override
  String timeoutsRemainingSemantics(String team, int count) {
    return '$team：残り$count回のタイムアウト';
  }
}
