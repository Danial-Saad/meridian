import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../services/notification_service.dart';
import '../utils/format_utils.dart';
import 'history.dart';
import 'persistence.dart';

DayStats _computeStats(List<Task> tasksForDay, int focusMinutesFromSessions) {
  final completed =
      tasksForDay.where((t) => t.status == TaskStatus.completed).length;
  final total = tasksForDay.length;
  final skipped =
      tasksForDay.where((t) => t.status == TaskStatus.skipped).length;
  final focusFromTasks = tasksForDay
      .where((t) => t.status == TaskStatus.completed)
      .fold<int>(0, (s, t) => s + t.duration);
  final focusMinutes = focusFromTasks + focusMinutesFromSessions;

  final upcoming = tasksForDay
      .where((t) =>
          t.status != TaskStatus.completed && t.status != TaskStatus.skipped)
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final nextTask = upcoming.isNotEmpty ? upcoming.first : null;

  final actionable = total - skipped;
  final productivityScore = actionable > 0
      ? clampInt(
          (((completed / actionable) * 70) +
                  ((focusMinutes / 240).clamp(0, 1) * 30))
              .round(),
          0,
          100,
        )
      : 0;

  return DayStats(
    completed: completed,
    total: total,
    skipped: skipped,
    actionable: actionable,
    pct: actionable > 0 ? ((completed / actionable) * 100).round() : 0,
    focusMinutes: focusMinutes,
    nextTask: nextTask,
    productivityScore: productivityScore,
  );
}

List<HabitWithStats> _computeHabitStats(List<Habit> habits) {
  return habits.map((h) {
    var streak = 0;
    var cursor = DateTime.now();

    // إذا لم تنجز العادة اليوم، ابدأ الفحص من الأمس للحفاظ على السلسلة
    if (h.logs[dayKey(cursor)] != true) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (h.logs[dayKey(cursor)] == true) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final sortedDates = h.logs.keys.map(parseDayKey).toList()
      ..sort((a, b) => a.compareTo(b));
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sortedDates) {
      if (prev != null && d.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }

    final today = DateTime.now();
    final last30 = List<bool>.generate(30, (i) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 29 - i));
      return h.logs[dayKey(d)] == true;
    });
    // BUG FIX: this used to always divide by a flat 30, regardless of how
    // long the habit has actually existed. A brand-new habit completed
    // perfectly for its first 3 days showed "10%" (3/30) — a number that
    // reads as a failing habit on day one. Divide by the number of days
    // since creation instead, capped at 30 once the habit's actually old
    // enough for the original window to be the right denominator.
    final createdAt = parseDayKey(h.createdDate);
    final daysSinceCreation =
        DateTime(today.year, today.month, today.day).difference(createdAt).inDays + 1;
    final completionWindow =
        daysSinceCreation < 1 ? 1 : (daysSinceCreation > 30 ? 30 : daysSinceCreation);
    final completedInWindow =
        last30.sublist(last30.length - completionWindow).where((v) => v).length;
    final completionRate = ((completedInWindow / completionWindow) * 100).round();
    final last7 = last30.sublist(last30.length - 7);

    // Same age-aware reasoning as the monthly window above, capped at 7
    // instead of 30 — a habit created yesterday is judged on a 2-day
    // week, not docked for the 5 days before it existed.
    final weeklyWindowDays =
        daysSinceCreation < 1 ? 1 : (daysSinceCreation > 7 ? 7 : daysSinceCreation);
    final weeklyCompletedDays =
        last7.sublist(last7.length - weeklyWindowDays).where((v) => v).length;
    final weeklyRate = ((weeklyCompletedDays / weeklyWindowDays) * 100).round();

    return HabitWithStats(
      habit: h,
      streak: streak,
      best: best,
      completionRate: completionRate,
      last30: last30,
      last7: last7,
      weeklyRate: weeklyRate,
      weeklyCompletedDays: weeklyCompletedDays,
      weeklyWindowDays: weeklyWindowDays,
      monthlyCompletedDays: completedInWindow,
      monthlyWindowDays: completionWindow,
    );
  }).toList();
}

class MeridianStore extends ChangeNotifier {
  MeridianData _data = createEmptyData();
  bool _hydrated = false;
  bool _isFreshInstall = false;
  ToastState? _toast;
  Timer? _saveTimer;
  Timer? _toastTimer;

  // Kept up to date by AppShell's build() on every rebuild (including
  // locale changes), so store methods deep in the data layer — with no
  // BuildContext of their own — can still produce a localized toast
  // message. Deliberately nullable: a handful of very-early calls (e.g.
  // the corrupted-data-recovery toast in _doInit, which can fire before
  // the first frame) may race ahead of the first setLocalizations call,
  // so every use below falls back to English rather than crashing.
  AppLocalizations? l10n;
  void setLocalizations(AppLocalizations value) {
    l10n = value;
  }

  DayStats? _statsCache;
  List<HabitWithStats>? _habitsCache;
  List<HistoryDay>? _historyCache;
  String? _cachedDayKey;

  void _invalidateDerivedCache() {
    _statsCache = null;
    _habitsCache = null;
    _historyCache = null;
  }

  void _refreshDayKeyIfNeeded() {
    final today = dayKey(DateTime.now());
    if (_cachedDayKey != today) {
      _cachedDayKey = today;
      _invalidateDerivedCache();
    }
  }

  MeridianData get rawData => _data;
  bool get hydrated => _hydrated;
  bool get isFreshInstall => _isFreshInstall;
  ToastState? get toast => _toast;

  List<Task> get tasks => _data.tasks;
  List<UserResource> get resources => _data.resources;
  UserSettings get settings => _data.settings;
  List<FocusLogEntry> get focusLog => _data.focusLog;
  Map<String, DailyReview> get reviews => _data.reviews;

  List<Task> get todaysTasks {
    final key = dayKey(DateTime.now());
    return _data.tasks.where((t) => t.taskDate == key).toList();
  }

  int get _todaysFocusMinutes {
    final key = dayKey(DateTime.now());
    return _data.focusLog
        .where((f) => dayKey(DateTime.fromMillisecondsSinceEpoch(f.at)) == key)
        .fold<int>(0, (s, f) => s + f.minutes);
  }

  DayStats get stats {
    _refreshDayKeyIfNeeded();
    return _statsCache ??= _computeStats(todaysTasks, _todaysFocusMinutes);
  }

  List<HabitWithStats> get habits {
    _refreshDayKeyIfNeeded();
    return _habitsCache ??= _computeHabitStats(_data.habits);
  }

  List<HistoryDay> get history {
    _refreshDayKeyIfNeeded();
    return _historyCache ??= buildHistory(_data.tasks, _data.focusLog);
  }

  bool get hasAnyData =>
      _data.tasks.isNotEmpty ||
      _data.habits.isNotEmpty ||
      _data.resources.isNotEmpty;

  Future<void>? _initFuture;

  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    final result = await loadData();
    _data = result.data;
    _isFreshInstall = result.isFresh;
    _hydrated = true;
    _invalidateDerivedCache();
    if (result.recoveredFromCorruption) {
      notify(ToastKind.error,
          l10n?.dataCorruptedRecoveredToast ??
              "Your saved data couldn't be read and was reset. If you have a backup, you can restore it from Settings.");
    }
    notifyListeners();
  }

  void _scheduleSave() {
    if (!_hydrated) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 150), () async {
      final ok = await saveData(_data);
      if (!ok) {
        notify(ToastKind.error,
            l10n?.saveFailedToast ??
                "Couldn't save your changes — your device may be low on storage.");
      }
    });
  }

  void _setData(MeridianData next) {
    _data = next;
    _invalidateDerivedCache();
    _scheduleSave();
    notifyListeners();
  }

  void notify(ToastKind kind, String text) {
    _toast = ToastState(kind: kind, text: text, key: uid());
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      _toast = null;
      notifyListeners();
    });
  }

  void dismissToast() {
    _toastTimer?.cancel();
    _toast = null;
    notifyListeners();
  }

  /* ---- Tasks ---- */
  void addTask(NewTask task) {
    final t = Task(
      id: uid(),
      title: task.title,
      category: task.category,
      priority: task.priority,
      status: task.status,
      start: task.start,
      duration: task.duration,
      notes: task.notes,
      taskDate: task.taskDate,
      link: task.link,
    );
    _setData(_data.copyWith(tasks: [..._data.tasks, t]));
    notify(ToastKind.success, l10n?.itemAddedToDayToast(task.title) ?? '"${task.title}" added to your day');
    // NOTIFICATIONS SYSTEM: fire-and-forget, same pattern _scheduleSave()
    // already uses for its own async side effect — scheduleTaskReminder
    // itself checks the taskRemindersEnabled setting isn't this store's
    // job to gate; see the call site's own no-op-if-not-ready guards.
    if (_data.settings.taskRemindersEnabled) NotificationService.scheduleTaskReminder(t);
  }

  void updateTask(String id, Task Function(Task) patch) {
    _setData(_data.copyWith(
      tasks: _data.tasks.map((t) {
        if (t.id != id) return t;

        var updatedTask = patch(t);
        if (updatedTask.taskDate.compareTo(t.taskDate) > 0) {
          updatedTask = updatedTask.copyWith(
            postponedCount: t.postponedCount + 1,
            // FEATURE (Analytics Feature 2 — delay *amount*, not just a
            // count): only set the very first time this task is ever
            // postponed (`t.originalDate == null`). A second or third
            // postponement leaves it alone, so it always holds the true
            // original date rather than the most recent "previous" one —
            // the gap between this and wherever `taskDate` ends up is the
            // *total* delay accumulated across every reschedule.
            originalDate: t.originalDate ?? t.taskDate,
          );
        }

        // An edit can move the date/time, change the title, or complete/
        // skip the task — rescheduling (which itself cancels if the new
        // time has passed or the task is done) covers all of those from
        // one call, keyed on the same deterministic per-task id so this
        // always replaces rather than stacking a duplicate.
        if (_data.settings.taskRemindersEnabled) {
          NotificationService.scheduleTaskReminder(updatedTask);
        }

        return updatedTask;
      }).toList(),
    ));
  }

  void deleteTask(String id) {
    final t = _data.tasks
        .where((x) => x.id == id)
        .cast<Task?>()
        .firstWhere((x) => true, orElse: () => null);
    _setData(
        _data.copyWith(tasks: _data.tasks.where((x) => x.id != id).toList()));
    if (t != null) notify(ToastKind.info, l10n?.itemRemovedToast(t.title) ?? '"${t.title}" removed');
    NotificationService.cancelTaskReminder(id);
  }

  void toggleTaskComplete(String id) {
    bool markedComplete = false;
    String? taskTitle;
    Task? toggled;

    final newTasks = _data.tasks.map((t) {
      if (t.id != id) return t;
      final nextStatus = t.status == TaskStatus.completed
          ? TaskStatus.todo
          : TaskStatus.completed;

      if (nextStatus == TaskStatus.completed) {
        markedComplete = true;
        taskTitle = t.title;
      }
      toggled = t.copyWith(status: nextStatus);
      return toggled!;
    }).toList();

    _setData(_data.copyWith(tasks: newTasks));

    if (markedComplete) notify(ToastKind.success, l10n?.taskCompleteToast(taskTitle ?? '') ?? '"$taskTitle" complete');
    // Completing cancels (nothing left to remind about); un-completing
    // (toggled back to todo) reschedules if the reminder window hasn't
    // already passed — scheduleTaskReminder's own guards handle both
    // outcomes from this one call.
    if (toggled != null && _data.settings.taskRemindersEnabled) {
      NotificationService.scheduleTaskReminder(toggled!);
    }
  }

  /* ---- Focus sessions ---- */
  void logFocusSession(String? taskId, int minutes) {
    _setData(_data.copyWith(focusLog: [
      ..._data.focusLog,
      FocusLogEntry(
          taskId: taskId,
          minutes: minutes,
          at: DateTime.now().millisecondsSinceEpoch),
    ]));
  }

  /* ---- Habits ---- */
  void addHabit(NewHabit habit) {
    final h = Habit(
        id: uid(),
        name: habit.name,
        emoji: habit.emoji,
        color: habit.color,
        logs: const {},
        reminderTime: habit.reminderTime,
        createdDate: habit.createdDate);
    _setData(_data.copyWith(habits: [..._data.habits, h]));
    notify(ToastKind.success, l10n?.habitAddedToast(habit.name) ?? '"${habit.name}" added to your habits');
    if (_data.settings.habitRemindersEnabled && !h.paused) NotificationService.scheduleHabitReminder(h);
  }

  void updateHabit(String id, Habit Function(Habit) patch) {
    Habit? patched;
    _setData(_data.copyWith(
      habits: _data.habits.map((h) {
        if (h.id != id) return h;
        patched = patch(h);
        return patched!;
      }).toList(),
    ));
    if (patched == null) return;
    if (_data.settings.habitRemindersEnabled && !patched!.paused) {
      NotificationService.scheduleHabitReminder(patched!);
    } else {
      NotificationService.cancelHabitReminder(id);
    }
  }

  // Pausing stops reminders immediately (regardless of the global
  // Settings toggle) and hides the habit from the Dashboard's "what's
  // left today" list, but keeps its logs, streak, and completion history
  // untouched — resuming picks back up exactly where it left off.
  void toggleHabitPaused(String id) {
    updateHabit(id, (h) => h.copyWith(paused: !h.paused));
  }

  void deleteHabit(String id) {
    final h = _data.habits
        .where((x) => x.id == id)
        .cast<Habit?>()
        .firstWhere((x) => true, orElse: () => null);
    _setData(
        _data.copyWith(habits: _data.habits.where((x) => x.id != id).toList()));
    if (h != null) notify(ToastKind.info, l10n?.itemRemovedToast(h.name) ?? '"${h.name}" removed');
    NotificationService.cancelHabitReminder(id);
  }

  void toggleHabitToday(String id) {
    final today = dayKey(DateTime.now());
    bool markedDone = false;
    String? habitEmoji;
    String? habitName;

    final newHabits = _data.habits.map((h) {
      if (h.id != id) return h;
      final logs = Map<String, bool>.from(h.logs);
      final wasDone = logs[today] == true;
      if (wasDone) {
        logs.remove(today);
      } else {
        logs[today] = true;
        markedDone = true;
        habitEmoji = h.emoji;
        habitName = h.name;
      }
      return h.copyWith(logs: logs);
    }).toList();

    _setData(_data.copyWith(habits: newHabits));

    if (markedDone) {
      notify(ToastKind.success,
          l10n?.habitLoggedTodayToast(habitEmoji ?? '', habitName ?? '') ??
              '$habitEmoji "$habitName" logged for today');
    }
  }

  /* ---- Resources ---- */
  void addResource(UserResource resource) {
    _setData(_data.copyWith(resources: [..._data.resources, resource]));
    notify(ToastKind.success, l10n?.resourceAddedToast(resource.title) ?? '"${resource.title}" added to resources');
  }

  void updateResource(String id, UserResource Function(UserResource) patch) {
    _setData(_data.copyWith(
      resources: _data.resources.map((r) => r.id == id ? patch(r) : r).toList(),
    ));
    notify(ToastKind.success, l10n?.resourceUpdatedToast ?? 'Resource updated');
  }

  void deleteResource(String id) {
    final r = _data.resources
        .where((x) => x.id == id)
        .cast<UserResource?>()
        .firstWhere((x) => true, orElse: () => null);
    _setData(_data.copyWith(
        resources: _data.resources.where((x) => x.id != id).toList()));
    if (r != null) {
      try {
        final file = dart_io.File(r.imagePath);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      notify(ToastKind.info, l10n?.itemRemovedToast(r.title) ?? '"${r.title}" removed');
    }
  }

  /* ---- Settings ---- */
  void updateSettings(UserSettings Function(UserSettings) patch) {
    final prev = _data.settings;
    final next = patch(prev);
    _setData(_data.copyWith(settings: next));
    // Only resync when something reminder-relevant actually changed —
    // toggling the theme or time format shouldn't touch notifications.
    if (prev.taskRemindersEnabled != next.taskRemindersEnabled ||
        prev.habitRemindersEnabled != next.habitRemindersEnabled ||
        prev.dailyPlanningRemindersEnabled !=
            next.dailyPlanningRemindersEnabled ||
        prev.dailyPlanningMorningHour != next.dailyPlanningMorningHour ||
        prev.dailyPlanningEveningHour != next.dailyPlanningEveningHour) {
      resyncAllReminders();
    }
  }

  /// NOTIFICATIONS SYSTEM: re-applies every task/habit/daily-planning
  /// reminder from scratch, based on the store's current data and
  /// settings. Called once after app startup (see splash_screen.dart) —
  /// this is what makes reminders self-heal after a device reboot, since
  /// AlarmManager-based alarms don't survive one on their own (see
  /// NotificationService's own doc comment for the full reasoning behind
  /// that trade-off) — and again whenever a reminder-related setting
  /// changes (see updateSettings above), so turning a toggle on
  /// retroactively schedules every already-existing eligible task/habit,
  /// not just ones created afterward.
  void resyncAllReminders() {
    if (_data.settings.taskRemindersEnabled) {
      for (final t in _data.tasks) {
        NotificationService.scheduleTaskReminder(t);
      }
    } else {
      for (final t in _data.tasks) {
        NotificationService.cancelTaskReminder(t.id);
      }
    }
    if (_data.settings.habitRemindersEnabled) {
      for (final h in _data.habits) {
        NotificationService.scheduleHabitReminder(h);
      }
    } else {
      for (final h in _data.habits) {
        NotificationService.cancelHabitReminder(h.id);
      }
    }
    // Self-contained: checks dailyPlanningRemindersEnabled itself and
    // cancels if off, so no if/else needed here.
    NotificationService.scheduleDailyPlanningReminders(_data.settings);
  }

  /* ---- Reviews ---- */
  void saveReview(String key, DailyReview review) {
    _setData(_data.copyWith(reviews: {..._data.reviews, key: review}));
    notify(ToastKind.success, l10n?.reflectionSavedToast ?? 'Reflection saved');
  }

  /* ---- Data management ---- */
  // BUG FIX (audit report #1): restoring a backup used to be a raw data
  // swap with zero notification bookkeeping. Two separate problems from
  // that: any reminder already scheduled with the OS for a task/habit id
  // that doesn't exist in the *restored* data kept sitting there
  // uncancelled — stale, pointing at content that's now gone — and any
  // task/habit in the restored data that has a reminder enabled would
  // NOT actually get one scheduled with the OS, since only the
  // create/update paths above ever call scheduleTaskReminder /
  // scheduleHabitReminder; a raw `_setData(next)` bypasses all of that
  // silently. Cancelling every reminder tied to the *old* data before
  // the swap, then calling the same `resyncAllReminders()` the app
  // already uses after startup and after a reminder-relevant settings
  // change, closes both gaps with logic that's already trusted elsewhere
  // rather than new, one-off code.
  void replaceAllData(MeridianData next) {
    for (final t in _data.tasks) {
      NotificationService.cancelTaskReminder(t.id);
    }
    for (final h in _data.habits) {
      NotificationService.cancelHabitReminder(h.id);
    }
    _setData(next);
    resyncAllReminders();
  }

  void resetAllData() {
    for (final r in _data.resources) {
      try {
        final file = dart_io.File(r.imagePath);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    // BUG FIX: this used to reset settings back to UserSettings.defaults()
    // too — silently wiping the person's name, language, pomodoro
    // durations, every notification toggle, and their blocked-apps list,
    // none of which the confirmation dialog ("This permanently deletes
    // every task, habit, focus session, and review...") ever mentioned.
    // Preserve settings; only the content the dialog actually describes
    // gets cleared.
    //
    // Also cancel every scheduled task/habit reminder explicitly first —
    // deleteTask/deleteHabit already do this one at a time, but this
    // path replaces the whole data set directly without going through
    // either of them, so without this loop any already-scheduled
    // reminder would keep firing later for a task or habit that no
    // longer exists.
    for (final t in _data.tasks) {
      NotificationService.cancelTaskReminder(t.id);
    }
    for (final h in _data.habits) {
      NotificationService.cancelHabitReminder(h.id);
    }
    _setData(createEmptyData().copyWith(settings: _data.settings));
    notify(ToastKind.info, l10n?.allDataResetToast ?? 'All local data has been reset');
  }

  void loadDemoData(MeridianData demo) {
    _setData(demo);
    notify(ToastKind.success, l10n?.exampleDataLoadedToast ?? 'Example data loaded');
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }
}
