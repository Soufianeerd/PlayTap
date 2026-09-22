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
}
