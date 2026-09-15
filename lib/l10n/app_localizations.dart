// ignore: unused_import
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
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

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('ru')
  ];

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @planMyDay.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get planMyDay;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @localization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get localization;

  /// No description provided for @focusDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus duration'**
  String get focusDuration;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @breakDuration.
  ///
  /// In en, this message translates to:
  /// **'Break duration'**
  String get breakDuration;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get taskReminders;

  /// No description provided for @taskRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Notify me 10 minutes before a task starts.'**
  String get taskRemindersSub;

  /// No description provided for @habitReminders.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders'**
  String get habitReminders;

  /// No description provided for @dailyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Daily planning'**
  String get dailyPlanning;

  /// No description provided for @dailyPlanningSub.
  ///
  /// In en, this message translates to:
  /// **'Morning and evening nudges to plan your day and review it.'**
  String get dailyPlanningSub;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesTitle;

  /// No description provided for @resourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your courses, documentation and useful links in one place.'**
  String get resourcesSubtitle;

  /// No description provided for @resourcesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No resources yet.'**
  String get resourcesEmptyTitle;

  /// No description provided for @addResourceButton.
  ///
  /// In en, this message translates to:
  /// **'Add Resource'**
  String get addResourceButton;

  /// No description provided for @todayWord.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayWord;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @addWord.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addWord;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// No description provided for @habitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small, repeated actions — tracked daily.'**
  String get habitsSubtitle;

  /// No description provided for @habitsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No habits yet.'**
  String get habitsEmptyTitle;

  /// No description provided for @habitsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track something small you want to do every day — Meridian will build the streak for you.'**
  String get habitsEmptySubtitle;

  /// No description provided for @addHabitButton.
  ///
  /// In en, this message translates to:
  /// **'Add a habit'**
  String get addHabitButton;

  /// No description provided for @habitDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this habit?'**
  String get habitDeleteTitle;

  /// No description provided for @dailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get streakLabel;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get bestLabel;

  /// No description provided for @day30Label.
  ///
  /// In en, this message translates to:
  /// **'30-DAY'**
  String get day30Label;

  /// No description provided for @doneTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get doneTodayLabel;

  /// No description provided for @markDoneTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark done today'**
  String get markDoneTodayLabel;

  /// No description provided for @daysAgo30Label.
  ///
  /// In en, this message translates to:
  /// **'30 days ago'**
  String get daysAgo30Label;

  /// No description provided for @categoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get categoryStudy;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get categoryProject;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @anyDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDateFilter;

  /// No description provided for @upcomingFilter.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingFilter;

  /// No description provided for @pastFilter.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastFilter;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @openFilter.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFilter;

  /// No description provided for @allCategoriesFilter.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategoriesFilter;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your task list is empty.'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first task, or try Plan My Day from the Dashboard.'**
  String get tasksEmptySubtitle;

  /// No description provided for @createTaskButton.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTaskButton;

  /// No description provided for @tasksNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks match these filters.'**
  String get tasksNoMatchTitle;

  /// No description provided for @tasksNoMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different status, category, or date range.'**
  String get tasksNoMatchSubtitle;

  /// No description provided for @taskDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get taskDeleteTitle;

  /// No description provided for @openLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLinkLabel;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning.'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon.'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening.'**
  String get greetingEvening;

  /// No description provided for @dashboardSubtitleEvening.
  ///
  /// In en, this message translates to:
  /// **'How did today go?'**
  String get dashboardSubtitleEvening;

  /// No description provided for @dashboardSubtitleDay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s make today count.'**
  String get dashboardSubtitleDay;

  /// No description provided for @dayReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Day review'**
  String get dayReviewButton;

  /// No description provided for @focusTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTimeLabel;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @dashboardClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day is clear.'**
  String get dashboardClearTitle;

  /// No description provided for @dashboardClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to make something happen?'**
  String get dashboardClearSubtitle;

  /// No description provided for @todaysScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaysScheduleTitle;

  /// No description provided for @openPlannerButton.
  ///
  /// In en, this message translates to:
  /// **'Open planner'**
  String get openPlannerButton;

  /// No description provided for @scheduleEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Nothing left on today\'s schedule.'**
  String get scheduleEmptyText;

  /// No description provided for @startFocusButton.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get startFocusButton;

  /// No description provided for @periodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get periodMorning;

  /// No description provided for @periodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get periodAfternoon;

  /// No description provided for @periodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get periodEvening;

  /// No description provided for @periodNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get periodNight;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerTitle;

  /// No description provided for @plannerHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a block to move it, its bottom edge to resize.'**
  String get plannerHint;

  /// No description provided for @previousDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDayTooltip;

  /// No description provided for @nextDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDayTooltip;

  /// No description provided for @jumpToTodayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Jump to today'**
  String get jumpToTodayTooltip;

  /// No description provided for @plannerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap any slot below to time-block a task.'**
  String get plannerEmptySubtitle;

  /// No description provided for @urgentBadge.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgentBadge;

  /// No description provided for @timeBlockDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this time block?'**
  String get timeBlockDeleteTitle;

  /// No description provided for @overlapErrorToast.
  ///
  /// In en, this message translates to:
  /// **'That overlaps another block — try a different time'**
  String get overlapErrorToast;

  /// No description provided for @focusSubtitleFocus.
  ///
  /// In en, this message translates to:
  /// **'One task. Full attention.'**
  String get focusSubtitleFocus;

  /// No description provided for @focusSubtitleBreak.
  ///
  /// In en, this message translates to:
  /// **'Step away for a moment.'**
  String get focusSubtitleBreak;

  /// No description provided for @blockDistractingAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Block distracting apps'**
  String get blockDistractingAppsTitle;

  /// No description provided for @workingOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Working on'**
  String get workingOnLabel;

  /// No description provided for @noTasksFreeSession.
  ///
  /// In en, this message translates to:
  /// **'No tasks remaining — free session'**
  String get noTasksFreeSession;

  /// No description provided for @focusPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get focusPhaseLabel;

  /// No description provided for @breakPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get breakPhaseLabel;

  /// No description provided for @freeSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Free session'**
  String get freeSessionLabel;

  /// No description provided for @startButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButtonLabel;

  /// No description provided for @resumeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButtonLabel;

  /// No description provided for @pauseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButtonLabel;

  /// No description provided for @resetButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButtonLabel;

  /// No description provided for @skipButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButtonLabel;

  /// No description provided for @completeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeButtonLabel;

  /// No description provided for @customPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customPresetLabel;

  /// No description provided for @focusFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusFieldLabel;

  /// No description provided for @breakFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakFieldLabel;

  /// No description provided for @yourTaskFallback.
  ///
  /// In en, this message translates to:
  /// **'your task'**
  String get yourTaskFallback;

  /// No description provided for @focusCompleteNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus session complete 🎉'**
  String get focusCompleteNotifTitle;

  /// No description provided for @breakOverToast.
  ///
  /// In en, this message translates to:
  /// **'Break\'s over — ready for another round?'**
  String get breakOverToast;

  /// No description provided for @breakOverNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Break\'s over'**
  String get breakOverNotifTitle;

  /// No description provided for @breakOverNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Ready for another round?'**
  String get breakOverNotifBody;

  /// No description provided for @blockAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Block Apps'**
  String get blockAppsTitle;

  /// No description provided for @noAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// No description provided for @permissionsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequiredTitle;

  /// No description provided for @accessibilityPermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Meridian needs Android\'s Accessibility permission to detect when a blocked app is opened during a Focus session.\n\nWe do not read your screen content.'**
  String get accessibilityPermissionExplanation;

  /// No description provided for @openAndroidSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Android Settings'**
  String get openAndroidSettingsButton;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune Meridian to how you actually work.'**
  String get settingsSubtitle;

  /// No description provided for @languageEffectImmediate.
  ///
  /// In en, this message translates to:
  /// **'Language takes effect immediately.'**
  String get languageEffectImmediate;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Both modes are designed intentionally, not inverted.'**
  String get themeDescription;

  /// No description provided for @darkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkLabel;

  /// No description provided for @lightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightLabel;

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLabel;

  /// No description provided for @timeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timeFormatLabel;

  /// No description provided for @timeFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'How times are displayed across the app.'**
  String get timeFormatDescription;

  /// No description provided for @format12h.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get format12h;

  /// No description provided for @format24h.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get format24h;

  /// No description provided for @weekStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get weekStartsLabel;

  /// No description provided for @weekStartsDescription.
  ///
  /// In en, this message translates to:
  /// **'Affects weekly views and reviews.'**
  String get weekStartsDescription;

  /// No description provided for @sundayLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sundayLabel;

  /// No description provided for @mondayLabel.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get mondayLabel;

  /// No description provided for @pomodoroFocusDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for the Custom Pomodoro preset.'**
  String get pomodoroFocusDescription;

  /// No description provided for @pomodoroBreakDescription.
  ///
  /// In en, this message translates to:
  /// **'Applied after each custom focus session.'**
  String get pomodoroBreakDescription;

  /// No description provided for @focusNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus session notifications'**
  String get focusNotificationsLabel;

  /// No description provided for @focusNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a Focus or Break timer ends, even if Meridian isn\'t the app you\'re looking at.'**
  String get focusNotificationsDescription;

  /// No description provided for @onLabel.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onLabel;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @habitRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a time per habit from its edit screen; this is the master switch.'**
  String get habitRemindersDescription;

  /// No description provided for @morningReminderHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder hour'**
  String get morningReminderHourLabel;

  /// No description provided for @eveningReminderHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder hour'**
  String get eveningReminderHourLabel;

  /// No description provided for @clock24hDescription.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock.'**
  String get clock24hDescription;

  /// No description provided for @hourUnit.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourUnit;

  /// No description provided for @yourDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourDataTitle;

  /// No description provided for @dataPrivacyText.
  ///
  /// In en, this message translates to:
  /// **'Meridian stores everything locally on this device — there\'s no account and nothing is uploaded anywhere. Export a backup periodically, especially before uninstalling or switching devices.'**
  String get dataPrivacyText;

  /// No description provided for @exportBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackupButton;

  /// No description provided for @importBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackupButton;

  /// No description provided for @loadExampleDataButton.
  ///
  /// In en, this message translates to:
  /// **'Load example data'**
  String get loadExampleDataButton;

  /// No description provided for @resetAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all local data?'**
  String get resetAllDataTitle;

  /// No description provided for @resetAllDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every task, habit, focus session, and review stored on this device. Consider exporting a backup first.'**
  String get resetAllDataDescription;

  /// No description provided for @resetEverythingButton.
  ///
  /// In en, this message translates to:
  /// **'Reset everything'**
  String get resetEverythingButton;

  /// No description provided for @resetAllDataButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset all local data'**
  String get resetAllDataButtonLabel;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @storageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageLabel;

  /// No description provided for @storageValue.
  ///
  /// In en, this message translates to:
  /// **'On this device only'**
  String get storageValue;

  /// No description provided for @accountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsLabel;

  /// No description provided for @accountsValue.
  ///
  /// In en, this message translates to:
  /// **'None — nothing to sign into'**
  String get accountsValue;

  /// No description provided for @backupReadyToast.
  ///
  /// In en, this message translates to:
  /// **'Backup ready to save'**
  String get backupReadyToast;

  /// No description provided for @backupCreateErrorToast.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the backup file.'**
  String get backupCreateErrorToast;

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current tasks, habits, and settings with the contents of the backup file. This can\'t be undone.'**
  String get restoreBackupDescription;

  /// No description provided for @restoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// No description provided for @backupRestoredToast.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestoredToast;

  /// No description provided for @couldntReadFileError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file.'**
  String get couldntReadFileError;

  /// No description provided for @notificationsOffFocusToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in your phone\'s settings — enable them there if you\'d like Focus alerts.'**
  String get notificationsOffFocusToast;

  /// No description provided for @notificationsOffTaskToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in your phone\'s settings — enable them there if you\'d like task reminders.'**
  String get notificationsOffTaskToast;

  /// No description provided for @notificationsOffHabitToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in your phone\'s settings — enable them there if you\'d like habit reminders.'**
  String get notificationsOffHabitToast;

  /// No description provided for @notificationsOffDailyPlanningToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in your phone\'s settings — enable them there if you\'d like daily planning reminders.'**
  String get notificationsOffDailyPlanningToast;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your time actually moved.'**
  String get analyticsSubtitle;

  /// No description provided for @thisWeekFilter.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekFilter;

  /// No description provided for @thisMonthFilter.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonthFilter;

  /// No description provided for @productivityScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Productivity score'**
  String get productivityScoreLabel;

  /// No description provided for @completionRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRateLabel;

  /// No description provided for @avgSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg session'**
  String get avgSessionLabel;

  /// No description provided for @executionConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Execution & Consistency'**
  String get executionConsistencyTitle;

  /// No description provided for @executionConsistencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Planned vs Completed tasks and Habit adherence'**
  String get executionConsistencySubtitle;

  /// No description provided for @focusTimeTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus time trend'**
  String get focusTimeTrendTitle;

  /// No description provided for @todaysFocusBySession.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus, by session'**
  String get todaysFocusBySession;

  /// No description provided for @last7DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'last 7 days'**
  String get last7DaysLabel;

  /// No description provided for @last28DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'last 28 days'**
  String get last28DaysLabel;

  /// No description provided for @categoryDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get categoryDistributionTitle;

  /// No description provided for @allActiveTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'All active tasks'**
  String get allActiveTasksLabel;

  /// No description provided for @completedVsSkippedTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed vs skipped'**
  String get completedVsSkippedTitle;

  /// No description provided for @dailyBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily breakdown'**
  String get dailyBreakdownLabel;

  /// No description provided for @habitCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit completion'**
  String get habitCompletionLabel;

  /// No description provided for @noFocusSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'No focus sessions logged yet today.'**
  String get noFocusSessionsToday;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @tasksWord.
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get tasksWord;

  /// No description provided for @noHabitsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYetShort;

  /// No description provided for @avgHabitConsistencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Habit Consistency'**
  String get avgHabitConsistencyLabel;

  /// No description provided for @taskDelaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Delays'**
  String get taskDelaysTitle;

  /// No description provided for @noPostponedTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No postponed tasks yet. Great job!'**
  String get noPostponedTasksSubtitle;

  /// No description provided for @patternsInPostponedTasks.
  ///
  /// In en, this message translates to:
  /// **'Patterns in postponed tasks'**
  String get patternsInPostponedTasks;

  /// No description provided for @delayedTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Delayed Tasks'**
  String get delayedTasksLabel;

  /// No description provided for @mostDelayedLabel.
  ///
  /// In en, this message translates to:
  /// **'Most Delayed'**
  String get mostDelayedLabel;

  /// No description provided for @habitCommitmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit Commitment'**
  String get habitCommitmentTitle;

  /// No description provided for @habitCommitmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Insights into your daily adherence'**
  String get habitCommitmentSubtitle;

  /// No description provided for @mostConsistentLabel.
  ///
  /// In en, this message translates to:
  /// **'Most Consistent'**
  String get mostConsistentLabel;

  /// No description provided for @needsAttentionLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttentionLabel;

  /// No description provided for @addHabitsToSeePatterns.
  ///
  /// In en, this message translates to:
  /// **'Add some habits to see your commitment patterns.'**
  String get addHabitsToSeePatterns;

  /// No description provided for @notEnoughFocusData.
  ///
  /// In en, this message translates to:
  /// **'Not enough focus data yet.'**
  String get notEnoughFocusData;

  /// No description provided for @notEnoughDailyReviews.
  ///
  /// In en, this message translates to:
  /// **'Not enough daily reviews yet.'**
  String get notEnoughDailyReviews;

  /// No description provided for @noTasksPostponed.
  ///
  /// In en, this message translates to:
  /// **'No tasks have been postponed.'**
  String get noTasksPostponed;

  /// No description provided for @productivityPatternsTitle.
  ///
  /// In en, this message translates to:
  /// **'Productivity Patterns'**
  String get productivityPatternsTitle;

  /// No description provided for @observedBehavioralTrends.
  ///
  /// In en, this message translates to:
  /// **'Observed behavioral trends (Data-driven)'**
  String get observedBehavioralTrends;

  /// No description provided for @dayNameMondayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Mondays'**
  String get dayNameMondayInSentence;

  /// No description provided for @dayNameTuesdayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Tuesdays'**
  String get dayNameTuesdayInSentence;

  /// No description provided for @dayNameWednesdayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Wednesdays'**
  String get dayNameWednesdayInSentence;

  /// No description provided for @dayNameThursdayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Thursdays'**
  String get dayNameThursdayInSentence;

  /// No description provided for @dayNameFridayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Fridays'**
  String get dayNameFridayInSentence;

  /// No description provided for @dayNameSaturdayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Saturdays'**
  String get dayNameSaturdayInSentence;

  /// No description provided for @dayNameSundayInSentence.
  ///
  /// In en, this message translates to:
  /// **'Sundays'**
  String get dayNameSundayInSentence;

  /// No description provided for @productivityInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Productivity Insights'**
  String get productivityInsightsTitle;

  /// No description provided for @whatRecentActivitySuggests.
  ///
  /// In en, this message translates to:
  /// **'What your recent activity suggests'**
  String get whatRecentActivitySuggests;

  /// No description provided for @keepUsingMeridianInsight.
  ///
  /// In en, this message translates to:
  /// **'Keep using Meridian for a few more days — insights show up here once there\'s enough data to spot real patterns.'**
  String get keepUsingMeridianInsight;

  /// No description provided for @periodMorningLower.
  ///
  /// In en, this message translates to:
  /// **'morning'**
  String get periodMorningLower;

  /// No description provided for @periodAfternoonLower.
  ///
  /// In en, this message translates to:
  /// **'afternoon'**
  String get periodAfternoonLower;

  /// No description provided for @periodEveningLower.
  ///
  /// In en, this message translates to:
  /// **'evening'**
  String get periodEveningLower;

  /// No description provided for @periodNightLower.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get periodNightLower;

  /// No description provided for @urgentTaskWordSingular.
  ///
  /// In en, this message translates to:
  /// **'urgent task'**
  String get urgentTaskWordSingular;

  /// No description provided for @urgentTaskWordPlural.
  ///
  /// In en, this message translates to:
  /// **'urgent tasks'**
  String get urgentTaskWordPlural;

  /// No description provided for @resourceNoLinkError.
  ///
  /// In en, this message translates to:
  /// **'This resource doesn\'t have a link.'**
  String get resourceNoLinkError;

  /// No description provided for @resourceInvalidLinkError.
  ///
  /// In en, this message translates to:
  /// **'That link doesn\'t look valid.'**
  String get resourceInvalidLinkError;

  /// No description provided for @resourceOpenLinkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that link.'**
  String get resourceOpenLinkError;

  /// No description provided for @editResourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Resource'**
  String get editResourceLabel;

  /// No description provided for @deleteResourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Resource'**
  String get deleteResourceLabel;

  /// No description provided for @resourceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this resource?'**
  String get resourceDeleteTitle;

  /// No description provided for @resourceGiveTitleError.
  ///
  /// In en, this message translates to:
  /// **'Give this resource a title.'**
  String get resourceGiveTitleError;

  /// No description provided for @resourceProvideUrlError.
  ///
  /// In en, this message translates to:
  /// **'Provide a URL for this resource.'**
  String get resourceProvideUrlError;

  /// No description provided for @resourceSelectImageError.
  ///
  /// In en, this message translates to:
  /// **'Please select an image.'**
  String get resourceSelectImageError;

  /// No description provided for @resourceSaveImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save image.'**
  String get resourceSaveImageError;

  /// No description provided for @editResourceModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit resource'**
  String get editResourceModalTitle;

  /// No description provided for @coverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImageLabel;

  /// No description provided for @tapToSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to select image (optional)'**
  String get tapToSelectImage;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @resourceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flutter Masterclass'**
  String get resourceTitleHint;

  /// No description provided for @resourceUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://example.com/course'**
  String get resourceUrlHint;

  /// No description provided for @resourceDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Complete guide to Flutter'**
  String get resourceDescHint;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @taskGiveTitleError.
  ///
  /// In en, this message translates to:
  /// **'Give this task a title.'**
  String get taskGiveTitleError;

  /// No description provided for @taskInvalidLinkError.
  ///
  /// In en, this message translates to:
  /// **'That link doesn\'t look like a valid URL.'**
  String get taskInvalidLinkError;

  /// No description provided for @editTaskModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTaskModalTitle;

  /// No description provided for @newTaskModalTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTaskModalTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deep work — thesis draft'**
  String get taskTitleHint;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @categoryLabelField.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabelField;

  /// No description provided for @priorityLabelField.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabelField;

  /// No description provided for @statusLabelField.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabelField;

  /// No description provided for @startHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Start hour'**
  String get startHourLabel;

  /// No description provided for @minuteLabel.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minuteLabel;

  /// No description provided for @durationMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get durationMinLabel;

  /// No description provided for @linkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkLabel;

  /// No description provided for @taskLinkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. coursera.org/learn/your-course'**
  String get taskLinkHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @yesDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get yesDeleteLabel;

  /// No description provided for @addToDayButton.
  ///
  /// In en, this message translates to:
  /// **'Add to day'**
  String get addToDayButton;

  /// No description provided for @habitGiveNameError.
  ///
  /// In en, this message translates to:
  /// **'Give this habit a name.'**
  String get habitGiveNameError;

  /// No description provided for @editHabitModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabitModalTitle;

  /// No description provided for @newHabitModalTitle.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabitModalTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Morning run'**
  String get habitNameHint;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @noReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminderLabel;

  /// No description provided for @topPrioritiesQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are your top priorities for the day?'**
  String get topPrioritiesQuestion;

  /// No description provided for @priorityHint1.
  ///
  /// In en, this message translates to:
  /// **'e.g. Finish thesis chapter 3'**
  String get priorityHint1;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @fixedCommitmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed commitments today (optional)'**
  String get fixedCommitmentsLabel;

  /// No description provided for @commitmentsHintExample.
  ///
  /// In en, this message translates to:
  /// **'One per line, e.g. "1pm - 2pm lunch with advisor"'**
  String get commitmentsHintExample;

  /// No description provided for @commitmentsFieldPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'9am - 10am standup\n1pm-2pm lunch'**
  String get commitmentsFieldPlaceholder;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @generateScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Generate schedule'**
  String get generateScheduleButton;

  /// No description provided for @addToMyDayButton.
  ///
  /// In en, this message translates to:
  /// **'Add to my day'**
  String get addToMyDayButton;

  /// No description provided for @endOfDayReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'End of day review'**
  String get endOfDayReviewTitle;

  /// No description provided for @tasksDoneStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks done'**
  String get tasksDoneStatLabel;

  /// No description provided for @focusedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get focusedStatLabel;

  /// No description provided for @whatWentWellLabel.
  ///
  /// In en, this message translates to:
  /// **'What went well today?'**
  String get whatWentWellLabel;

  /// No description provided for @whatCouldImproveLabel.
  ///
  /// In en, this message translates to:
  /// **'What could be improved?'**
  String get whatCouldImproveLabel;

  /// No description provided for @saveReflectionButton.
  ///
  /// In en, this message translates to:
  /// **'Save reflection'**
  String get saveReflectionButton;

  /// No description provided for @exitMeridianTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Meridian?'**
  String get exitMeridianTitle;

  /// No description provided for @exitMeridianDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit Meridian?'**
  String get exitMeridianDesc;

  /// No description provided for @exitLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitLabel;

  /// No description provided for @notCompletedSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompletedSemanticLabel;

  /// No description provided for @doubleTapMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Double tap to mark as not done'**
  String get doubleTapMarkNotDone;

  /// No description provided for @doubleTapMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Double tap to mark as done'**
  String get doubleTapMarkDone;

  /// No description provided for @dataCorruptedRecoveredToast.
  ///
  /// In en, this message translates to:
  /// **'Your saved data couldn\'t be read and was reset. If you have a backup, you can restore it from Settings.'**
  String get dataCorruptedRecoveredToast;

  /// No description provided for @saveFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes — your device may be low on storage.'**
  String get saveFailedToast;

  /// No description provided for @resourceUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Resource updated'**
  String get resourceUpdatedToast;

  /// No description provided for @reflectionSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Reflection saved'**
  String get reflectionSavedToast;

  /// No description provided for @allDataResetToast.
  ///
  /// In en, this message translates to:
  /// **'All local data has been reset'**
  String get allDataResetToast;

  /// No description provided for @exampleDataLoadedToast.
  ///
  /// In en, this message translates to:
  /// **'Example data loaded'**
  String get exampleDataLoadedToast;

  /// No description provided for @startingSoonNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get startingSoonNotifTitle;

  /// No description provided for @habitReminderNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit reminder'**
  String get habitReminderNotifTitle;

  /// No description provided for @goodMorningNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorningNotifTitle;

  /// No description provided for @readyToPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan your day?'**
  String get readyToPlanBody;

  /// No description provided for @dayAlmostOverNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Day almost over'**
  String get dayAlmostOverNotifTitle;

  /// No description provided for @takeMomentReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to review how it went.'**
  String get takeMomentReviewBody;

  /// No description provided for @breakTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakTaskTitle;

  /// No description provided for @focusBlockFallback.
  ///
  /// In en, this message translates to:
  /// **'Focus block'**
  String get focusBlockFallback;

  /// No description provided for @generatedByPlanMyDayNote.
  ///
  /// In en, this message translates to:
  /// **'Generated by Plan My Day'**
  String get generatedByPlanMyDayNote;

  /// No description provided for @continuedSuffix.
  ///
  /// In en, this message translates to:
  /// **' (cont.)'**
  String get continuedSuffix;

  /// No description provided for @viewAllLabel.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllLabel;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @yourNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Used to personalize greetings on the dashboard.'**
  String get yourNameDescription;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sam'**
  String get yourNameHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @addNameBannerText.
  ///
  /// In en, this message translates to:
  /// **'Add your name for a more personal greeting'**
  String get addNameBannerText;

  /// No description provided for @noThanksLabel.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get noThanksLabel;

  /// No description provided for @whatShouldWeCallYouTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get whatShouldWeCallYouTitle;

  /// No description provided for @overdueBadge.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdueBadge;

  /// No description provided for @jumpToNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Jump to now'**
  String get jumpToNowTooltip;

  /// No description provided for @noTimeLeftTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'There\'s no time left in today\'s schedule to plan around — try a different day, or add a task directly from the Planner.'**
  String get noTimeLeftTodayMessage;

  /// No description provided for @addAnotherPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Add another priority'**
  String get addAnotherPriorityLabel;

  /// No description provided for @taskInvalidDurationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration in minutes (1–1440).'**
  String get taskInvalidDurationError;

  /// No description provided for @searchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasksHint;

  /// No description provided for @habitRemindersOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders are turned off in Settings — this won\'t notify you until you turn them on.'**
  String get habitRemindersOffWarning;

  /// No description provided for @turnOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOnLabel;

  /// No description provided for @pauseHabitLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseHabitLabel;

  /// No description provided for @pausedHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedHabitsTitle;

  /// No description provided for @resetSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this session?'**
  String get resetSessionTitle;

  /// No description provided for @resetSessionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this session will be lost.'**
  String get resetSessionDesc;

  /// No description provided for @searchResourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Search resources...'**
  String get searchResourcesHint;

  /// No description provided for @resourcesNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No resources match your search.'**
  String get resourcesNoMatchTitle;

  /// No description provided for @thisWeekSoFarLabel.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get thisWeekSoFarLabel;

  /// No description provided for @backupErrorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t valid JSON.'**
  String get backupErrorInvalidJson;

  /// No description provided for @backupErrorNotABackup.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t look like a Meridian backup.'**
  String get backupErrorNotABackup;

  /// No description provided for @backupErrorWrongApp.
  ///
  /// In en, this message translates to:
  /// **'This file wasn\'t exported from Meridian.'**
  String get backupErrorWrongApp;

  /// No description provided for @backupErrorMissingData.
  ///
  /// In en, this message translates to:
  /// **'This backup file is missing its data.'**
  String get backupErrorMissingData;

  /// No description provided for @backupErrorCorruptData.
  ///
  /// In en, this message translates to:
  /// **'This backup file\'s data is incomplete or corrupted.'**
  String get backupErrorCorruptData;

  /// No description provided for @habitDeleteDescStreak.
  ///
  /// In en, this message translates to:
  /// **'"{name}" and its {days}-day streak will be permanently removed.'**
  String habitDeleteDescStreak(String name, int days);

  /// No description provided for @habitDeleteDescHistory.
  ///
  /// In en, this message translates to:
  /// **'"{name}" and its history will be permanently removed.'**
  String habitDeleteDescHistory(String name);

  /// No description provided for @tasksSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} total · {completed} completed'**
  String tasksSummary(int total, int completed);

  /// No description provided for @taskDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'"{title}" will be permanently removed.'**
  String taskDeleteDesc(String title);

  /// No description provided for @upNextLabel.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT · {start} → {end}'**
  String upNextLabel(String start, String end);

  /// No description provided for @habitStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String habitStreakDays(int count);

  /// No description provided for @tasksDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} tasks done'**
  String tasksDoneLabel(int completed, int total);

  /// No description provided for @timeBlockDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'"{title}" will be removed from your planner.'**
  String timeBlockDeleteDesc(String title);

  /// No description provided for @appsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps selected'**
  String appsSelectedCount(int count);

  /// No description provided for @focusCompleteToast.
  ///
  /// In en, this message translates to:
  /// **'Focus session complete 🎉 — {mins} min on "{title}"'**
  String focusCompleteToast(int mins, String title);

  /// No description provided for @focusCompleteNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{mins} min on "{title}" — nice work.'**
  String focusCompleteNotifBody(int mins, String title);

  /// No description provided for @minutesPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes per day · {range}'**
  String minutesPerDayLabel(String range);

  /// No description provided for @ofFocusTarget.
  ///
  /// In en, this message translates to:
  /// **'of a {hours}h focus target'**
  String ofFocusTarget(int hours);

  /// No description provided for @pctOfTodaysTarget.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of today\'s target'**
  String pctOfTodaysTarget(int pct);

  /// No description provided for @minPerDayPoint.
  ///
  /// In en, this message translates to:
  /// **'{mins} min · {date}'**
  String minPerDayPoint(int mins, String date);

  /// No description provided for @plannedVsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned vs Completed ({completed}/{total} tasks)'**
  String plannedVsCompletedLabel(int completed, int total);

  /// No description provided for @categoryBreakdownRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks · {range}'**
  String categoryBreakdownRangeLabel(String range);

  /// No description provided for @plannedVsActualTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned vs Actual Time ({planned} planned · {actual} actual)'**
  String plannedVsActualTimeLabel(String planned, String actual);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySun;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDec;

  /// No description provided for @monthShortJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthShortDec;

  /// No description provided for @periodAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get periodAm;

  /// No description provided for @periodPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get periodPm;

  /// No description provided for @couldntLoadAppsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn't load your apps. Try again.'**
  String get couldntLoadAppsError;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @searchAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchAppsHint;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Meridian'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your day, planned with intention — tasks, habits, and focus, all in one place.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day, then focus'**
  String get onboardingPlanTitle;

  /// No description provided for @onboardingPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lay out your day on the Planner, then use Focus Mode to work on one thing at a time — distraction-free.'**
  String get onboardingPlanSubtitle;

  /// No description provided for @onboardingHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Build habits that stick'**
  String get onboardingHabitsTitle;

  /// No description provided for @onboardingHabitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track daily habits and see real patterns in Analytics — actual insight into how you work, not just charts.'**
  String get onboardingHabitsSubtitle;

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meridian can gently remind you about tasks, habits, and your daily plan — only what you turn on, nothing more.'**
  String get onboardingNotifSubtitle;

  /// No description provided for @onboardingNextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNextButton;

  /// No description provided for @onboardingGetStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStartedButton;

  /// No description provided for @enableNotificationsButton.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotificationsButton;

  /// No description provided for @notNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNowButton;

  /// No description provided for @perHabitBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Per-habit breakdown'**
  String get perHabitBreakdownLabel;

  /// No description provided for @missedDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Missed {missed} of {total} days'**
  String missedDaysLabel(int missed, int total);

  /// No description provided for @averageDelayDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Average delay (days)'**
  String get averageDelayDaysLabel;

  /// No description provided for @byCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryLabel;

  /// No description provided for @byPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get byPriorityLabel;

  /// No description provided for @currentlyOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue right now'**
  String currentlyOverdueLabel(int count);

  /// No description provided for @overallPctLabel.
  ///
  /// In en, this message translates to:
  /// **'{pct}% overall'**
  String overallPctLabel(int pct);

  /// No description provided for @peakFocusOccurs.
  ///
  /// In en, this message translates to:
  /// **'Peak focus occurs in the {period} ({mins} mins logged).'**
  String peakFocusOccurs(String period, int mins);

  /// No description provided for @highestCompletionRateDay.
  ///
  /// In en, this message translates to:
  /// **'Highest task completion rate is typically on {day} ({pct}%).'**
  String highestCompletionRateDay(String day, int pct);

  /// No description provided for @postponingPriorityTasks.
  ///
  /// In en, this message translates to:
  /// **'Frequently postponing \'{priority}\' priority tasks ({count} times).'**
  String postponingPriorityTasks(String priority, int count);

  /// No description provided for @completionUpInsight.
  ///
  /// In en, this message translates to:
  /// **'Your task completion rate is up {diff}% this week compared to last week — whatever changed, keep it up.'**
  String completionUpInsight(int diff);

  /// No description provided for @completionDownInsight.
  ///
  /// In en, this message translates to:
  /// **'Your task completion rate is down {diff}% compared to last week.'**
  String completionDownInsight(int diff);

  /// No description provided for @completionSteadyInsight.
  ///
  /// In en, this message translates to:
  /// **'Your task completion rate is holding steady week over week ({pct}%).'**
  String completionSteadyInsight(int pct);

  /// No description provided for @strongestHabitStreak.
  ///
  /// In en, this message translates to:
  /// **'{emoji} \'{name}\' is on a {days}-day streak — your strongest habit right now.'**
  String strongestHabitStreak(String emoji, String name, int days);

  /// No description provided for @lapsedHabitInsight.
  ///
  /// In en, this message translates to:
  /// **'{emoji} \'{name}\' is usually solid ({pct}% overall) but hasn\'t been logged the last couple of days.'**
  String lapsedHabitInsight(String emoji, String name, int pct);

  /// No description provided for @goodAlignmentInsight.
  ///
  /// In en, this message translates to:
  /// **'Good alignment: you schedule most tasks in the {period}, which is also when your focus sessions run longest.'**
  String goodAlignmentInsight(String period);

  /// No description provided for @misalignedFocusInsight.
  ///
  /// In en, this message translates to:
  /// **'You focus best in the {focusPeriod}, but most completed tasks are scheduled in the {taskPeriod}. Try moving important work to your peak window.'**
  String misalignedFocusInsight(String focusPeriod, String taskPeriod);

  /// No description provided for @urgentTaskPostponedSingular.
  ///
  /// In en, this message translates to:
  /// **'\'{title}\' is urgent, still open, and has already been postponed once — worth tackling next.'**
  String urgentTaskPostponedSingular(String title);

  /// No description provided for @urgentTasksPostponedPlural.
  ///
  /// In en, this message translates to:
  /// **'\'{title}\' and {extra} other {taskWord} have already been postponed and are still open.'**
  String urgentTasksPostponedPlural(String title, int extra, String taskWord);

  /// No description provided for @priorityFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority {n}'**
  String priorityFieldLabel(int n);

  /// No description provided for @hoursAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours available for focused work: {hours}h'**
  String hoursAvailableLabel(String hours);

  /// No description provided for @blocksGeneratedReview.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks generated — review before adding them to your day.'**
  String blocksGeneratedReview(int count);

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{mins} min'**
  String durationMinutesLabel(int mins);

  /// No description provided for @blocksAddedToast.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks added to your day'**
  String blocksAddedToast(int count);

  /// No description provided for @itemAddedToDayToast.
  ///
  /// In en, this message translates to:
  /// **'"{title}" added to your day'**
  String itemAddedToDayToast(String title);

  /// No description provided for @itemRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'"{title}" removed'**
  String itemRemovedToast(String title);

  /// No description provided for @taskCompleteToast.
  ///
  /// In en, this message translates to:
  /// **'"{title}" complete'**
  String taskCompleteToast(String title);

  /// No description provided for @habitAddedToast.
  ///
  /// In en, this message translates to:
  /// **'"{name}" added to your habits'**
  String habitAddedToast(String name);

  /// No description provided for @habitLoggedTodayToast.
  ///
  /// In en, this message translates to:
  /// **'{emoji} "{name}" logged for today'**
  String habitLoggedTodayToast(String emoji, String name);

  /// No description provided for @resourceAddedToast.
  ///
  /// In en, this message translates to:
  /// **'"{title}" added to resources'**
  String resourceAddedToast(String title);

  /// No description provided for @taskStartsInBody.
  ///
  /// In en, this message translates to:
  /// **'"{title}" starts in {mins} minutes.'**
  String taskStartsInBody(String title, int mins);

  /// No description provided for @timeForHabitBody.
  ///
  /// In en, this message translates to:
  /// **'Time for "{name}".'**
  String timeForHabitBody(String name);

  /// No description provided for @moreItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreItemsLabel(int count);

  /// No description provided for @greetingMorningNamed.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}.'**
  String greetingMorningNamed(String name);

  /// No description provided for @greetingAfternoonNamed.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}.'**
  String greetingAfternoonNamed(String name);

  /// No description provided for @greetingEveningNamed.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}.'**
  String greetingEveningNamed(String name);

  /// No description provided for @trendVsYesterday.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs yesterday'**
  String trendVsYesterday(String delta);

  /// No description provided for @minimumTimeWarning.
  ///
  /// In en, this message translates to:
  /// **'With {count} priorities, each gets at least 30 min — that\'s {neededHours}h total, more than the {setHours}h you\'ve set.'**
  String minimumTimeWarning(int count, String neededHours, String setHours);

  /// No description provided for @unparsedCommitmentsWarning.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t figure out a time for: {lines} — won\'t be blocked off.'**
  String unparsedCommitmentsWarning(String lines);

}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ar', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
