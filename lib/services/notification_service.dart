import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import 'pending_navigation.dart';

/// NOTIFICATIONS SYSTEM — the full type taxonomy actually implemented.
///
/// Deliberately scoped to the four categories with a dedicated brief
/// section and a Settings toggle (Task, Habit, Focus/Break, Daily
/// Planning). An "overdue task" or fully generic "reminder" type was
/// considered (the brief's own ID-scheme example mentions them) but left
/// out: neither has a concrete settings entry or trigger in this app,
/// and the brief's closing line is explicit about prioritizing
/// reliability and maintainability over unrequested features. See
/// MERIDIAN_UX_PLAN.md for the fuller reasoning.
enum MeridianNotificationType {
  taskReminder,
  habitReminder,
  focusComplete,
  breakComplete,
  dailyPlanningMorning,
  dailyPlanningEvening,
}

extension on MeridianNotificationType {
  /// Stable string used in both the notification payload (for tap
  /// routing) and log/debug output. Never persisted to disk and never
  /// shown to the user, so it's safe to treat as an internal wire format.
  String get wireName {
    switch (this) {
      case MeridianNotificationType.taskReminder:
        return 'task';
      case MeridianNotificationType.habitReminder:
        return 'habit';
      case MeridianNotificationType.focusComplete:
        return 'focus';
      case MeridianNotificationType.breakComplete:
        return 'break';
      case MeridianNotificationType.dailyPlanningMorning:
        return 'plan_morning';
      case MeridianNotificationType.dailyPlanningEvening:
        return 'plan_evening';
    }
  }
}

/// A stable string hash (same input -> same output, forever, across app
/// restarts and Dart/Flutter versions) used to derive notification IDs
/// deterministically from entity UUIDs. Deliberately NOT using dart:core's
/// `String.hashCode`: that hash is only guaranteed stable *within a
/// single run* — the language does not promise it stays the same across
/// isolates or VM versions. If it ever changed between app sessions,
/// cancel-by-id and reschedule-by-id would silently stop finding what a
/// previous session created, which is exactly the duplicate-notification
/// failure mode the brief calls out. This is a plain FNV-1a 32-bit hash:
/// simple, well-known, and entirely under this file's own control.
int _stableHash(String input) {
  int hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// Deterministic notification-id namespaces. Ranges are chosen with wide
/// margins and don't overlap, so a task and a habit can never collide
/// with each other or with the small set of fixed singleton ids — see
/// each constant below for the reasoning.
class _NotificationIds {
  // Singleton notification types: only one can ever be relevant at a
  // time, so a fixed id is simpler than hashing anything, and doubles as
  // "replace the previous one of this type" for free (posting a new
  // notification with the same id replaces it rather than stacking).
  static const int focusComplete = 1;
  static const int breakComplete = 2;
  static const int dailyPlanningMorning = 3;
  static const int dailyPlanningEvening = 4;

  // Task reminders: one id per task, derived from the task's own uid()
  // string (8 lowercase alphanumeric chars) so the same task always maps
  // to the same id in any app session — required for cancel/reschedule
  // on edit or delete to reliably find the original.
  static int forTask(String taskId) =>
      10000000 + (_stableHash(taskId) % 500000000);

  // Habit reminders: same idea, offset into a completely separate range
  // so a task and a habit can never land on the same id even in the
  // (astronomically unlikely, birthday-paradox-bounded) case of a hash
  // collision within one type's own range.
  static int forHabit(String habitId) =>
      600000000 + (_stableHash(habitId) % 500000000);
}

/// NOTIFICATIONS SYSTEM.
///
/// Centralizes everything about local notifications in one place, per
/// the brief's explicit "avoid scattering scheduling logic across
/// screens" requirement — the only other files that touch notifications
/// at all are `meridian_store.dart` (calls schedule/cancel from its
/// existing task/habit CRUD methods, since that's the one place every
/// mutation already flows through regardless of which screen triggered
/// it) and `main.dart`/`app_shell.dart` (wiring, not logic).
///
/// Design choices worth calling out up front:
/// - Task and Habit reminders schedule with
///   `AndroidScheduleMode.exactAllowWhileIdle`, falling back to
///   `inexactAllowWhileIdle` only if exact-alarm access isn't available
///   (see `_scheduleWithFallback`). This was originally inexact-only for
///   battery-friendliness, but real-world testing showed that choice was
///   wrong for a short lead time: Android's own alarm batching/Doze-mode
///   deferral can delay an inexact alarm by more than "10 minutes before"
///   can tolerate, so the reminder arrived late or not at all — the
///   opposite of useful. Exact scheduling needs `SCHEDULE_EXACT_ALARM`
///   (requested from Settings when Task/Habit reminders are turned on,
///   not bundled into the first-launch prompt — see
///   `requestExactAlarmPermissionIfNeeded`), which is why the fallback
///   exists: that permission can be declined, and has been reported
///   locked/unavailable on some OEM builds. Daily Planning reminders stay
///   on `inexactAllowWhileIdle` unconditionally — "around 8am" has no
///   precision requirement worth the added permission complexity.
/// - Reminders are re-synced from the store's current data every time the
///   app starts (see `MeridianStore`'s call into this from init), rather
///   than relying on a native boot-receiver + background isolate to
///   survive a device reboot. `AlarmManager`-based alarms (which this
///   plugin uses under the hood) do NOT survive a reboot on their own —
///   that part of the brief's concern is real — but a full boot-receiver
///   solution needs a separate native entry point and a background Dart
///   isolate with its own plugin re-registration, which is meaningfully
///   more complex and, without a real device available to test against,
///   meaningfully riskier to get right than this app's other native
///   changes have been. The trade-off is explicit and narrow: a reminder
///   whose fire time falls *while the device is off* and the app is not
///   reopened before then is missed for that one occurrence. Given this
///   is a daily-use productivity app, that's judged an acceptable,
///   clearly-documented limitation rather than something worth the added
///   risk right now — see MERIDIAN_UX_PLAN.md for the fuller reasoning
///   and what a follow-up boot-receiver implementation would need.
class NotificationService {
  NotificationService._();

  // Kept up to date by AppShell's build() on every rebuild (including
  // locale changes) — mirrors the same pattern MeridianStore uses. These
  // notifications are scheduled ahead of time (sometimes recurring daily)
  // by the native plugin, so the title/body text has to be resolved at
  // schedule time from whatever locale is current then; every use below
  // falls back to English if a schedule call somehow races ahead of the
  // first setLocalizations call.
  static AppLocalizations? l10n;
  static void setLocalizations(AppLocalizations value) {
    l10n = value;
  }

  static const String _channelReminders = 'meridian_reminders';
  static const String _channelFocus = 'meridian_focus';

  // "Your task starts in 10 minutes" — the lead time is a named constant
  // so it's the one place to change, not a magic number buried in a
  // scheduling call.
  static const int taskReminderLeadMinutes = 10;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timezoneReady = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return; // idempotent — see MeridianStore.init() for why this matters
    }

    if (!_timezoneReady) {
      tz_data.initializeTimeZones();
      try {
        final String deviceZone =
            (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(deviceZone));
      } catch (_) {
        // Unknown/unrecognized zone name on this device, or the platform
        // call itself failed: fall back to UTC rather than crashing
        // startup over a notification feature. Scheduled times will be
        // computed correctly relative to *a* fixed zone; only the
        // human-readable local time could be off on whatever handful of
        // devices hit this fallback.
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
      _timezoneReady = true;
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const settings = InitializationSettings(android: androidSettings);

    // BUG FIX (audit report #7, most severe instance): this whole block
    // used to run with no error handling, called from splash_screen.dart
    // inside a `Future.wait([...])` that also has none around this
    // specific call — a thrown exception here wouldn't just skip
    // notification setup, it would propagate out of the `Future.wait`
    // itself and could strand the app on its splash screen, unable to
    // ever navigate to AppShell, over what should be a fully optional
    // feature. Leaving `_initialized` false on failure means every other
    // method's own `if (!_initialized) return;` guard quietly no-ops
    // instead — a device that hits this loses notifications, not the
    // ability to open the app.
    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleForegroundResponse,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundResponse,
      );

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl
            .createNotificationChannel(const AndroidNotificationChannel(
          _channelReminders,
          'Meridian Reminders',
          description: 'Task, habit, and daily planning reminders',
          importance: Importance.defaultImportance,
        ));
        await androidImpl
            .createNotificationChannel(const AndroidNotificationChannel(
          _channelFocus,
          'Meridian Focus',
          description: 'Focus and break session alerts',
          importance: Importance.high,
        ));
      }

      _initialized = true;

      // Cold start via notification tap: the app process didn't exist yet
      // when the tap happened, so there was no running Dart callback to
      // handle it — this is the only way to recover that intent. Recorded
      // now, before SplashScreen navigates to AppShell, so it's already
      // waiting to be applied the moment AppShell's first frame mounts.
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        _route(launchDetails.notificationResponse?.payload);
      }
    } catch (_) {
      // Fails safe — see the comment above. _initialized stays false.
    }
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return false;
    }
    try {
      return await android.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static const String _hasAskedInitialPermissionKey =
      'meridian_has_asked_initial_notification_permission';

  /// Proactively asks for notification permission the very first time the
  /// app is opened, rather than waiting for the person to visit Settings
  /// and flip a toggle first. Uses its own small SharedPreferences flag —
  /// deliberately not a `UserSettings` field, since this is one-time app
  /// bookkeeping ("have we ever asked"), not a user-editable preference
  /// the Settings screen shows — so it only ever prompts once, on the
  /// actual first launch, regardless of how many times the app is
  /// reopened afterward.
  static Future<bool> requestInitialPermissionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasAskedInitialPermissionKey) == true) {
      return false; // Already asked
    }
    await prefs.setBool(_hasAskedInitialPermissionKey, true);
    return await requestPermission(); // Return the user's choice
  }

  /// Exact-alarm scheduling access is a separate, Android-specific grant
  /// from `POST_NOTIFICATIONS` — it's requested by navigating the person
  /// to a system settings screen (there's no in-app dialog for it), which
  /// is a bigger interruption than the notification-permission prompt.
  /// Deliberately NOT bundled into the first-launch prompt above for that
  /// reason; called instead from Settings at the moment Task or Habit
  /// reminders are actually turned on, since that's the point the person
  /// is expressing real intent to use a feature that benefits from it.
  /// Reminders still work without this — see `_scheduleWithFallback` —
  /// just with less precise timing.
  static Future<void> requestExactAlarmPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }
    try {
      final canSchedule =
          await android.canScheduleExactNotifications() ?? false;
      if (!canSchedule) {
        await android.requestExactAlarmsPermission();
      }
    } catch (_) {
      // Fails safe — reminders still work without this, just with less
      // precise timing (see the doc comment above and
      // `_scheduleWithFallback`).
    }
  }

  /// Immediate, unscheduled notification — used for Focus/Break session
  /// completion, which fires from live app state, not a stored date/time.
  static Future<void> show({
    required String title,
    required String body,
    MeridianNotificationType type = MeridianNotificationType.focusComplete,
  }) async {
    if (!_initialized) {
      return;
    }
    final id = type == MeridianNotificationType.breakComplete
        ? _NotificationIds.breakComplete
        : _NotificationIds.focusComplete;
    // BUG FIX (audit report #7): none of the plugin calls in this file
    // outside of `_scheduleWithFallback` and timezone detection were
    // wrapped in error handling — a thrown PlatformException here (revoked
    // permission, an OEM notification quirk) would propagate straight out
    // into whatever flow triggered it (a focus session completing, a task
    // being saved), interrupting something that has nothing to do with
    // notifications. Every plugin call below now fails safe: catch, do
    // nothing further, same "a notification not showing is better than a
    // crash" reasoning already applied to timezone detection above.
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelFocus,
            'Meridian Focus',
            channelDescription: 'Focus and break session alerts',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF0EA5E9),
          ),
        ),
        payload: '${type.wireName}|',
      );
    } catch (_) {
      // Fails safe — see the comment above.
    }
  }

  // --- Task reminders -------------------------------------------------

  /// Schedules with exact timing, falling back to inexact if that isn't
  /// available. Centralized here since task and habit reminders both need
  /// it: real-world testing showed inexact scheduling can be delayed by
  /// Android's own alarm batching/Doze-mode deferral by more than a short
  /// lead time can tolerate — a "starts in 10 minutes" reminder is
  /// useless if the OS decides to deliver it 20 minutes late. Exact
  /// alarms need `SCHEDULE_EXACT_ALARM`, which is not guaranteed granted
  /// (the person may decline it, and it's been reported locked/
  /// unavailable on some OEM builds — see NotificationService's own class
  /// doc), so this always has a working fallback rather than letting the
  /// reminder silently fail to schedule at all.
  static Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (_) {
        // Both the exact and inexact scheduling attempts failed — fails
        // safe, same reasoning as show() above, rather than letting this
        // propagate into whatever task/habit save triggered it.
      }
    }
  }

  /// Schedules (or, if one already exists for this task, silently
  /// replaces — `zonedSchedule` with the same id overwrites in place)
  /// a reminder `taskReminderLeadMinutes` before the task's own
  /// `taskDate`/`start`. Does nothing if that moment has already passed,
  /// or if the task is already completed/skipped — there's nothing
  /// useful to remind about either way.
  static Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized || !_timezoneReady) {
      return;
    }
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.skipped) {
      await cancelTaskReminder(task.id);
      return;
    }
    final fireAt = _taskDateTime(task)
        .subtract(const Duration(minutes: taskReminderLeadMinutes));
    final now = DateTime.now();
    if (!fireAt.isAfter(now)) {
      // Already in the past (or inside the lead window) — nothing
      // meaningful to schedule; make sure a stale one isn't left behind
      // from before this task's time was edited earlier.
      await cancelTaskReminder(task.id);
      return;
    }
    await _scheduleWithFallback(
      id: _NotificationIds.forTask(task.id),
      title: l10n?.startingSoonNotifTitle ?? 'Starting soon',
      body: l10n?.taskStartsInBody(task.title, taskReminderLeadMinutes) ??
          '"${task.title}" starts in $taskReminderLeadMinutes minutes.',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Meridian Reminders',
          channelDescription: 'Task, habit, and daily planning reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF0EA5E9),
        ),
      ),
      payload: '${MeridianNotificationType.taskReminder.wireName}|${task.id}',
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_NotificationIds.forTask(taskId));
    } catch (_) {}
  }

  static DateTime _taskDateTime(Task task) {
    final parts = task.taskDate.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2])
        .add(Duration(minutes: task.start));
  }

  // --- Habit reminders -------------------------------------------------

  /// Schedules a daily-recurring reminder at the habit's own
  /// `reminderTime` ("HH:mm"), or cancels any existing one if
  /// `reminderTime` is null. `matchDateTimeComponents: DateTimeComponents
  /// .time` is what makes this recur every day at that time-of-day
  /// indefinitely from a single call — the plugin reschedules the next
  /// occurrence itself after each fire, so there's no need for this app
  /// to re-issue the call daily.
  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (!_initialized || !_timezoneReady) {
      return;
    }
    final time = habit.reminderTime;
    if (time == null) {
      await cancelHabitReminder(habit.id);
      return;
    }
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final now = DateTime.now();
    var fireAt = DateTime(now.year, now.month, now.day, hour, minute);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }

    await _scheduleWithFallback(
      id: _NotificationIds.forHabit(habit.id),
      title: l10n?.habitReminderNotifTitle ?? 'Habit reminder',
      body: l10n?.timeForHabitBody(habit.name) ?? 'Time for "${habit.name}".',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Meridian Reminders',
          channelDescription: 'Task, habit, and daily planning reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF0EA5E9),
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${MeridianNotificationType.habitReminder.wireName}|${habit.id}',
    );
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_NotificationIds.forHabit(habitId));
    } catch (_) {}
  }

  // --- Daily planning ---------------------------------------------------

  /// Two fixed daily recurring nudges toward features that already exist
  /// (Plan My Day, End of Day Review) — see MERIDIAN_UX_PLAN.md for why
  /// the times themselves are a plain settings-stored hour rather than a
  /// full time-picker control.
  static Future<void> scheduleDailyPlanningReminders(
      UserSettings settings) async {
    if (!_initialized || !_timezoneReady) {
      return;
    }
    if (!settings.dailyPlanningRemindersEnabled) {
      await cancelDailyPlanningReminders();
      return;
    }
    await _scheduleDailyFixed(
      id: _NotificationIds.dailyPlanningMorning,
      hour: settings.dailyPlanningMorningHour,
      title: l10n?.goodMorningNotifTitle ?? 'Good morning',
      body: l10n?.readyToPlanBody ?? 'Ready to plan your day?',
      payload: '${MeridianNotificationType.dailyPlanningMorning.wireName}|',
    );
    await _scheduleDailyFixed(
      id: _NotificationIds.dailyPlanningEvening,
      hour: settings.dailyPlanningEveningHour,
      title: l10n?.dayAlmostOverNotifTitle ?? 'Day almost over',
      body: l10n?.takeMomentReviewBody ?? 'Take a moment to review how it went.',
      payload: '${MeridianNotificationType.dailyPlanningEvening.wireName}|',
    );
  }

  static Future<void> cancelDailyPlanningReminders() async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_NotificationIds.dailyPlanningMorning);
      await _plugin.cancel(_NotificationIds.dailyPlanningEvening);
    } catch (_) {}
  }

  static Future<void> _scheduleDailyFixed({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = DateTime.now();
    var fireAt = DateTime(now.year, now.month, now.day, hour);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(fireAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelReminders,
            'Meridian Reminders',
            channelDescription: 'Task, habit, and daily planning reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Color(0xFF0EA5E9),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (_) {}
  }

  // --- Tap routing -------------------------------------------------------

  static void _handleForegroundResponse(NotificationResponse response) {
    _route(response.payload);
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundResponse(NotificationResponse response) {
    _route(response.payload);
  }

  /// Maps a notification's payload to the tab AppShell should land on.
  /// See pending_navigation.dart for why this is a value handoff rather
  /// than this file reaching into AppShell directly. Deliberately routes
  /// to a *tab*, not a specific item within it (e.g. the exact task) —
  /// none of the existing screens support deep-linking to a specific
  /// entity by id today, and adding that is a materially bigger change
  /// than this pass's brief. Documented as a known limitation.
  static void _route(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    final sep = payload.indexOf('|');
    final type = sep == -1 ? payload : payload.substring(0, sep);
    switch (type) {
      case 'task':
        PendingNavigation.requestTab(1); // Planner — see class doc above
        break;
      case 'habit':
        PendingNavigation.requestTab(4); // Habits
        break;
      case 'focus':
      case 'break':
        PendingNavigation.requestTab(2); // Focus
        break;
      case 'plan_morning':
      case 'plan_evening':
        PendingNavigation.requestTab(0); // Dashboard
        break;
    }
  }
}
