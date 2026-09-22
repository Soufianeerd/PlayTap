// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navActivities => 'الأنشطة';

  @override
  String get navHistory => 'السجل';

  @override
  String get appTagline => 'النتيجة والمؤقت، جاهزان بلمسة واحدة.';

  @override
  String get languageSettingsTooltip => 'اللغة';

  @override
  String get resumeActivity => 'متابعة النشاط';

  @override
  String get categoryScore => 'تسجيل النتيجة';

  @override
  String get categoryTimer => 'تشغيل المؤقت';

  @override
  String get scoreSectionTitle => 'النتيجة';

  @override
  String get presetFreeScore => 'نتيجة حرة';

  @override
  String get timerSectionTitle => 'المؤقت';

  @override
  String get timerModeStopwatch => 'ساعة إيقاف';

  @override
  String get timerModeCountdown => 'عد تنازلي';

  @override
  String get timerModeLaps => 'الأشواط';

  @override
  String get timerModeInterval => 'فاصل زمني';

  @override
  String get newScoreTitle => 'نتيجة جديدة';

  @override
  String get participantCountLabel => 'عدد المشاركين';

  @override
  String participantNameLabel(int n) {
    return 'اسم المشارك $n';
  }

  @override
  String defaultParticipantName(int n) {
    return 'اللاعب $n';
  }

  @override
  String get startButton => 'ابدأ';

  @override
  String get finishGameDialogTitle => 'هل تريد إنهاء هذه المباراة؟';

  @override
  String get finishSessionDialogTitle => 'هل تريد إنهاء هذه الجلسة؟';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get finishButton => 'إنهاء';

  @override
  String get undoLastPoint => 'تراجع عن آخر نقطة';

  @override
  String get finishGameButton => 'إنهاء المباراة';

  @override
  String addPointSemantics(String name) {
    return 'إضافة نقطة لـ $name';
  }

  @override
  String errorPrefix(String error) {
    return 'خطأ: $error';
  }

  @override
  String get summaryTitle => 'الملخص';

  @override
  String get lessThanAMinute => 'أقل من دقيقة';

  @override
  String minutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get viewHistoryButton => 'عرض السجل';

  @override
  String get activeSessionDialogTitle => 'يوجد نشاط قيد التقدم بالفعل';

  @override
  String get activeSessionDialogContent =>
      'يمكنك متابعة النشاط الحالي أو التخلي عنه لبدء نشاط جديد.';

  @override
  String get abandonAndStart => 'التخلي والبدء';

  @override
  String get comingSoonTitle => 'قيد التطوير الداخلي';

  @override
  String comingSoonBody(String section) {
    return '$section لم يتم تفعيله بعد.';
  }

  @override
  String get comingSoonDefaultSection => 'هذا القسم';

  @override
  String get timeRemainingSemantics => 'الوقت المتبقي';

  @override
  String get timeElapsedSemantics => 'الوقت المنقضي';

  @override
  String get pauseButtonLabel => 'إيقاف مؤقت';

  @override
  String get resumeTimerButtonLabel => 'متابعة';

  @override
  String get pauseSemantics => 'إيقاف مؤقت';

  @override
  String get resumeTimerSemantics => 'متابعة';

  @override
  String get lapButton => 'شوط';

  @override
  String get recordLapSemantics => 'تسجيل شوط';

  @override
  String get finishSessionButton => 'إنهاء الجلسة';

  @override
  String lapRowLabel(int number) {
    return 'الشوط $number';
  }

  @override
  String lapsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شوط',
      many: '$count شوطًا',
      few: '$count أشواط',
      two: 'شوطان',
      one: 'شوط واحد',
      zero: 'لا أشواط',
    );
    return '$_temp0';
  }

  @override
  String get quickDurationLabel => 'مدة سريعة';

  @override
  String get customDurationLabel => 'مدة مخصصة (بالثواني)';

  @override
  String get durationValidationError => 'اختر مدة أكبر من 0.';

  @override
  String quickPresetSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String get emptyHistoryTitle => 'لا يوجد نشاط بعد.';

  @override
  String get emptyHistorySubtitle => 'ابدأ نتيجة أو مؤقتًا للبدء.';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get languagePageTitle => 'اللغة';

  @override
  String get languageSystemOption => 'تلقائي';

  @override
  String get presetPetanque => 'البيتانك';

  @override
  String get petanqueConfigTitle => 'مباراة بيتانك جديدة';

  @override
  String get petanqueFormatLabel => 'الصيغة';

  @override
  String get petanqueFormatHeadToHead => 'فردي';

  @override
  String get petanqueFormatDoublette => 'زوجي';

  @override
  String get petanqueFormatTriplette => 'ثلاثي';

  @override
  String petanqueTeamSectionLabel(int n) {
    return 'الفريق $n';
  }

  @override
  String get petanqueTeamNameLabel => 'اسم الفريق';

  @override
  String petanqueDefaultTeamName(int n) {
    return 'الفريق $n';
  }

  @override
  String endNumberLabel(int n) {
    return 'الجولة $n';
  }

  @override
  String endsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جولة',
      many: '$count جولة',
      few: '$count جولات',
      two: 'جولتان',
      one: 'جولة واحدة',
      zero: '$count جولة',
    );
    return '$_temp0';
  }

  @override
  String get undoLastRound => 'التراجع عن آخر جولة';

  @override
  String addRoundPointsSemantics(int amount, String team) {
    return 'أضف $amount نقاط إلى $team';
  }

  @override
  String get abandonGameButton => 'التخلي';

  @override
  String get abandonGameDialogTitle => 'هل تريد التخلي عن هذه المباراة؟';

  @override
  String winnerAnnouncement(String name) {
    return '$name يفوز!';
  }
}
