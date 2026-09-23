import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Bottom navigation label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Activities tab, and that tab's AppBar title.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get navActivities;

  /// Bottom navigation label for the History tab, and that tab's AppBar title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Home screen subtitle under the PlayTap wordmark.
  ///
  /// In en, this message translates to:
  /// **'Score and timer, ready in one tap.'**
  String get appTagline;

  /// Tooltip/semantics label for the Home screen's language settings icon button.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTooltip;

  /// Button that resumes the single in-progress session. Shown on Home and in the active-session conflict dialog.
  ///
  /// In en, this message translates to:
  /// **'RESUME ACTIVITY'**
  String get resumeActivity;

  /// Activity category tile label: start a Score session.
  ///
  /// In en, this message translates to:
  /// **'Keep score'**
  String get categoryScore;

  /// Activity category tile label: start a Timer session.
  ///
  /// In en, this message translates to:
  /// **'Time an activity'**
  String get categoryTimer;

  /// AppBar title for the Score presets list page.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreSectionTitle;

  /// Name of the only Score preset in this release. Used as a list item, page title, and history entry label.
  ///
  /// In en, this message translates to:
  /// **'Free score'**
  String get presetFreeScore;

  /// AppBar title for the Timer presets page, and the generic Timer title shown when no specific mode applies.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerSectionTitle;

  /// Name of the Stopwatch timer mode.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get timerModeStopwatch;

  /// Name of the Countdown timer mode.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get timerModeCountdown;

  /// Name of the Lap Timer mode.
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get timerModeLaps;

  /// Name of the Interval timer mode (not yet reachable in the UI; reserved for the future Interval Engine).
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get timerModeInterval;

  /// AppBar title for the Free Score configuration page.
  ///
  /// In en, this message translates to:
  /// **'New score'**
  String get newScoreTitle;

  /// Label above the 2/3/4 participant count selector.
  ///
  /// In en, this message translates to:
  /// **'Number of participants'**
  String get participantCountLabel;

  /// Text field label for one participant's name.
  ///
  /// In en, this message translates to:
  /// **'Participant {n} name'**
  String participantNameLabel(int n);

  /// Default, editable placeholder name pre-filled in a participant name field.
  ///
  /// In en, this message translates to:
  /// **'Player {n}'**
  String defaultParticipantName(int n);

  /// Button that starts a new Score or Timer session.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startButton;

  /// Confirmation dialog title when ending a Score session.
  ///
  /// In en, this message translates to:
  /// **'Finish this game?'**
  String get finishGameDialogTitle;

  /// Confirmation dialog title when ending a Timer session.
  ///
  /// In en, this message translates to:
  /// **'Finish this session?'**
  String get finishSessionDialogTitle;

  /// Cancel action in a confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelButton;

  /// Confirm action in the finish-session/finish-game dialogs.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get finishButton;

  /// Label on the compact undo bar during an active Score session.
  ///
  /// In en, this message translates to:
  /// **'Undo last point'**
  String get undoLastPoint;

  /// Button that opens the finish-game confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'FINISH THE GAME'**
  String get finishGameButton;

  /// Accessibility label for a participant's tappable score tile.
  ///
  /// In en, this message translates to:
  /// **'Add a point to {name}'**
  String addPointSemantics(String name);

  /// Generic inline error message, prefixed to the underlying error text.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// AppBar title for the Score and Timer summary pages.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// Session duration caption shown instead of "0 min" for very short sessions.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute'**
  String get lessThanAMinute;

  /// Compact session duration, e.g. "5 min". Also reused for the countdown quick-preset minute labels.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one {{minutes} min} other {{minutes} min}}'**
  String minutesShort(int minutes);

  /// Button on a summary page that navigates to History.
  ///
  /// In en, this message translates to:
  /// **'VIEW HISTORY'**
  String get viewHistoryButton;

  /// Title of the dialog shown when starting a new session while one is already active.
  ///
  /// In en, this message translates to:
  /// **'An activity is already in progress'**
  String get activeSessionDialogTitle;

  /// Body text of the active-session conflict dialog.
  ///
  /// In en, this message translates to:
  /// **'You can resume the current activity or abandon it to start a new one.'**
  String get activeSessionDialogContent;

  /// Button that abandons the in-progress session and starts a new one.
  ///
  /// In en, this message translates to:
  /// **'ABANDON AND START'**
  String get abandonAndStart;

  /// Placeholder page title for a section without an engine yet.
  ///
  /// In en, this message translates to:
  /// **'Under internal construction'**
  String get comingSoonTitle;

  /// Placeholder page body naming the unimplemented section.
  ///
  /// In en, this message translates to:
  /// **'{section} is not implemented yet.'**
  String comingSoonBody(String section);

  /// Fallback section name when none was passed to the placeholder page.
  ///
  /// In en, this message translates to:
  /// **'This section'**
  String get comingSoonDefaultSection;

  /// Accessibility label for the big countdown display.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get timeRemainingSemantics;

  /// Accessibility label for the big stopwatch/lap-timer display.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get timeElapsedSemantics;

  /// Button that pauses a running timer.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pauseButtonLabel;

  /// Button that resumes a paused timer.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resumeTimerButtonLabel;

  /// Accessibility label for the pause/resume timer button when it pauses.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseSemantics;

  /// Accessibility label for the pause/resume timer button when it resumes.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeTimerSemantics;

  /// Short button that records a lap split. Keep it very short — this is a large tap target on a live timer screen.
  ///
  /// In en, this message translates to:
  /// **'LAP'**
  String get lapButton;

  /// Accessibility label for the LAP button.
  ///
  /// In en, this message translates to:
  /// **'Record a lap'**
  String get recordLapSemantics;

  /// Button that opens the finish-session confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'FINISH SESSION'**
  String get finishSessionButton;

  /// Row label in the live lap list, e.g. "Lap 1".
  ///
  /// In en, this message translates to:
  /// **'Lap {number}'**
  String lapRowLabel(int number);

  /// Standalone lap count, e.g. "3 laps", shown on the Timer summary page.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} lap} other {{count} laps}}'**
  String lapsCountPlural(int count);

  /// Label above the countdown quick-duration pill selector.
  ///
  /// In en, this message translates to:
  /// **'Quick duration'**
  String get quickDurationLabel;

  /// Text field label for a manually entered countdown duration.
  ///
  /// In en, this message translates to:
  /// **'Custom duration (seconds)'**
  String get customDurationLabel;

  /// Validation message shown under the custom duration field when it is invalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration greater than 0.'**
  String get durationValidationError;

  /// Compact seconds label on a quick-duration pill, e.g. "30s".
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String quickPresetSeconds(int seconds);

  /// History page empty-state headline.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get emptyHistoryTitle;

  /// History page empty-state supporting text.
  ///
  /// In en, this message translates to:
  /// **'Start a score or a timer to get started.'**
  String get emptyHistorySubtitle;

  /// Relative day label for a history entry started today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Relative day label for a history entry started yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// AppBar title for the language settings page.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePageTitle;

  /// Option that follows the phone's system language.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get languageSystemOption;

  /// Name of the Pétanque Score preset. Used as a list item, page title, and history entry label.
  ///
  /// In en, this message translates to:
  /// **'Pétanque'**
  String get presetPetanque;

  /// AppBar title for the Pétanque configuration page.
  ///
  /// In en, this message translates to:
  /// **'New pétanque game'**
  String get petanqueConfigTitle;

  /// Label above the tête-à-tête/doublette/triplette format selector.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get petanqueFormatLabel;

  /// Pétanque format: 1 player per side (tête-à-tête).
  ///
  /// In en, this message translates to:
  /// **'Head-to-head'**
  String get petanqueFormatHeadToHead;

  /// Pétanque format: 2 players per side.
  ///
  /// In en, this message translates to:
  /// **'Doublette'**
  String get petanqueFormatDoublette;

  /// Pétanque format: 3 players per side.
  ///
  /// In en, this message translates to:
  /// **'Triplette'**
  String get petanqueFormatTriplette;

  /// Section header above one team's name and player fields on the Pétanque config page.
  ///
  /// In en, this message translates to:
  /// **'Team {n}'**
  String petanqueTeamSectionLabel(int n);

  /// Text field label for a team's name on the Pétanque config page.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get petanqueTeamNameLabel;

  /// Default, editable placeholder team name pre-filled in a Pétanque team name field.
  ///
  /// In en, this message translates to:
  /// **'Team {n}'**
  String petanqueDefaultTeamName(int n);

  /// Small, discreet label showing the current round number during an active Pétanque game ("mène" in French pétanque terminology).
  ///
  /// In en, this message translates to:
  /// **'End {n}'**
  String endNumberLabel(int n);

  /// Standalone count of completed Pétanque rounds ("mènes"), e.g. "7 ends", shown in History and the Pétanque summary page.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} end} other {{count} ends}}'**
  String endsCountPlural(int count);

  /// Label on the compact undo bar during an active Pétanque session (undoes the whole last round/"mène", not a single point).
  ///
  /// In en, this message translates to:
  /// **'Undo last end'**
  String get undoLastRound;

  /// Accessibility label for one of a team's +1..+6 round-scoring buttons during an active Pétanque session.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} points to {team}'**
  String addRoundPointsSemantics(int amount, String team);

  /// Button/tooltip that opens the abandon-game confirmation during an active Pétanque session, and its confirm action.
  ///
  /// In en, this message translates to:
  /// **'ABANDON'**
  String get abandonGameButton;

  /// Confirmation dialog title when manually abandoning a Pétanque session before it's won.
  ///
  /// In en, this message translates to:
  /// **'Abandon this game?'**
  String get abandonGameDialogTitle;

  /// Winner announcement on the Pétanque summary page.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String winnerAnnouncement(String name);

  /// Name of the Basketball Score preset. Used as a list item, page title, and history entry label. FIBA is a brand name and is never translated.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get presetBasketball;

  /// Name of the Football Score preset. Used as a list item, page title, and history entry label.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get presetFootball;

  /// Name of the Futsal Score preset. Used as a list item, page title, and history entry label. FIFA is a brand name and is never translated.
  ///
  /// In en, this message translates to:
  /// **'Futsal'**
  String get presetFutsal;

  /// AppBar title for the Basketball configuration page.
  ///
  /// In en, this message translates to:
  /// **'New basketball match'**
  String get basketballConfigTitle;

  /// AppBar title for the Football configuration page.
  ///
  /// In en, this message translates to:
  /// **'New football match'**
  String get footballConfigTitle;

  /// AppBar title for the Futsal configuration page.
  ///
  /// In en, this message translates to:
  /// **'New futsal match'**
  String get futsalConfigTitle;

  /// Label above the league/knockout format selector on the Football/Futsal configuration page.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get teamMatchFormatLabel;

  /// Match format: a draw is allowed, no extra time or shootout.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get teamMatchFormatLeague;

  /// Match format: extra time then a penalty shootout if still level — never ends in a draw.
  ///
  /// In en, this message translates to:
  /// **'Knockout'**
  String get teamMatchFormatKnockout;

  /// Section header above one team's name field on the Basketball/Football/Futsal configuration page.
  ///
  /// In en, this message translates to:
  /// **'Team {n}'**
  String teamMatchTeamSectionLabel(int n);

  /// Text field label for a team's name on the Basketball/Football/Futsal configuration page.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamMatchTeamNameLabel;

  /// Default, editable placeholder team name pre-filled in a Basketball/Football/Futsal team name field.
  ///
  /// In en, this message translates to:
  /// **'Team {n}'**
  String teamMatchDefaultTeamName(int n);

  /// Current-period label for a 4-quarter sport (Basketball).
  ///
  /// In en, this message translates to:
  /// **'Q{n}'**
  String periodLabelQuarter(int n);

  /// Current-period label for the first half of a 2-half sport (Football, Futsal).
  ///
  /// In en, this message translates to:
  /// **'1st half'**
  String get periodLabelFirstHalf;

  /// Current-period label for the second half of a 2-half sport (Football, Futsal).
  ///
  /// In en, this message translates to:
  /// **'2nd half'**
  String get periodLabelSecondHalf;

  /// Current-period label while playing overtime/extra time.
  ///
  /// In en, this message translates to:
  /// **'OT {n}'**
  String overtimeLabel(int n);

  /// Small badge next to a running match clock showing the referee-announced added time, in minutes (e.g. "+3").
  ///
  /// In en, this message translates to:
  /// **'+{minutes}'**
  String addedTimeBadge(int minutes);

  /// Label on the compact undo bar during an active Basketball/Football/Futsal session (undoes the single most recent point, period ending, or shootout attempt).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoLastActionLabel;

  /// Tooltip/label for the secondary actions ("...") menu during an active match.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActionsButton;

  /// Secondary-menu action that manually ends the current period on a running-clock sport (Football) — nothing auto-expires a running clock.
  ///
  /// In en, this message translates to:
  /// **'End period'**
  String get endPeriodManuallyButton;

  /// Confirmation dialog title before manually ending the current period.
  ///
  /// In en, this message translates to:
  /// **'End this period now?'**
  String get endPeriodDialogTitle;

  /// Secondary-menu action that opens the added-time picker on a running-clock sport (Football).
  ///
  /// In en, this message translates to:
  /// **'Added time'**
  String get announceAddedTimeButton;

  /// Title of the dialog offering added-time minute options.
  ///
  /// In en, this message translates to:
  /// **'Added time'**
  String get addedTimeDialogTitle;

  /// One selectable added-time option, in minutes (e.g. "+3 min").
  ///
  /// In en, this message translates to:
  /// **'+{n} min'**
  String addedTimeMinutesOption(int n);

  /// Title shown once a match enters the penalty shootout phase.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout'**
  String get shootoutLabel;

  /// Button recording a scored penalty-shootout attempt.
  ///
  /// In en, this message translates to:
  /// **'SCORED'**
  String get shootoutScoreButton;

  /// Button recording a missed penalty-shootout attempt.
  ///
  /// In en, this message translates to:
  /// **'MISSED'**
  String get shootoutMissButton;

  /// Indicates which team takes the next penalty-shootout attempt.
  ///
  /// In en, this message translates to:
  /// **'{team} to kick'**
  String shootoutNextKickerLabel(String team);

  /// Shootout score shown on the summary page, kept separate from the match score it never merges into.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout: {scoreA} – {scoreB}'**
  String shootoutScoreLine(int scoreA, int scoreB);

  /// Result label on the summary page when a league match ends level.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get matchDrawResultLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
