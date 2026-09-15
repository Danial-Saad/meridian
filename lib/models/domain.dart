/// Domain types for Meridian's local-first data model.
library;

enum TaskCategory { study, work, personal, health, project }

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, completed, skipped }

TaskCategory taskCategoryFromString(String s) => TaskCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskCategory.study,
    );

TaskPriority taskPriorityFromString(String s) => TaskPriority.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskPriority.medium,
    );

String taskStatusToWire(TaskStatus s) {
  switch (s) {
    case TaskStatus.todo:
      return 'todo';
    case TaskStatus.inProgress:
      return 'in_progress';
    case TaskStatus.completed:
      return 'completed';
    case TaskStatus.skipped:
      return 'skipped';
  }
}

TaskStatus taskStatusFromWire(String s) {
  switch (s) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'completed':
      return TaskStatus.completed;
    case 'skipped':
      return TaskStatus.skipped;
    default:
      return TaskStatus.todo;
  }
}

class Task {
  final String id;
  final String title;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final int start;
  final int duration;
  final String notes;
  final String taskDate;
  final String? link;
  final int postponedCount;
  // FEATURE (Analytics Feature 2 — "no delay amount" was a documented
  // gap: `postponedCount` says *how many times* a task was pushed back,
  // but nothing recorded *by how much*. Set once, the first time a task
  // is ever postponed (see `updateTask` in meridian_store.dart) — left
  // untouched on any later postponement, so it always holds the true
  // original date rather than the most recent "previous" one, and the
  // gap between this and the current `taskDate` is the *total* delay
  // accumulated across every reschedule, not just the latest move. Null
  // for a task that's never been postponed, including all pre-existing
  // tasks/backups from before this field existed (see `fromJson` below).
  final String? originalDate;

  const Task({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.start,
    required this.duration,
    required this.notes,
    required this.taskDate,
    this.link,
    this.postponedCount = 0,
    this.originalDate,
  });

  Task copyWith({
    String? title,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    int? start,
    int? duration,
    String? notes,
    String? taskDate,
    Object? link = _unset,
    int? postponedCount,
    Object? originalDate = _unset,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      taskDate: taskDate ?? this.taskDate,
      link: identical(link, _unset) ? this.link : link as String?,
      postponedCount: postponedCount ?? this.postponedCount,
      originalDate: identical(originalDate, _unset)
          ? this.originalDate
          : originalDate as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'priority': priority.name,
        'status': taskStatusToWire(status),
        'start': start,
        'duration': duration,
        'notes': notes,
        'taskDate': taskDate,
        if (link != null) 'link': link,
        'postponedCount': postponedCount,
        if (originalDate != null) 'originalDate': originalDate,
      };

  factory Task.fromJson(Map<String, dynamic> json, {String? fallbackDate}) {
    return Task(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      category:
          taskCategoryFromString((json['category'] as String?) ?? 'study'),
      priority:
          taskPriorityFromString((json['priority'] as String?) ?? 'medium'),
      status: taskStatusFromWire((json['status'] as String?) ?? 'todo'),
      start: (json['start'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 30,
      notes: (json['notes'] as String?) ?? '',
      taskDate: (json['taskDate'] as String?) ?? fallbackDate ?? '',
      link: json['link'] as String?,
      postponedCount: (json['postponedCount'] as num?)?.toInt() ?? 0,
      // Absent on any task saved before this field existed — null is
      // exactly right for those, not a fallback needing a real value:
      // "never postponed" is unknowable for old data, and treating it as
      // "not postponed" (rather than guessing a date) is the honest
      // default.
      originalDate: json['originalDate'] as String?,
    );
  }
}

class NewTask {
  final String title;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final int start;
  final int duration;
  final String notes;
  final String taskDate;
  final String? link;

  const NewTask({
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.start,
    required this.duration,
    required this.notes,
    required this.taskDate,
    this.link,
  });
}

class Habit {
  final String id;
  final String name;
  final String emoji;
  final String color;
  final Map<String, bool> logs;
  final String? reminderTime;
  // Day-key ("YYYY-MM-DD") the habit was created on. Used so the 30-day
  // completion-rate stat divides by how long the habit has actually
  // existed rather than always by 30 — without this, a brand-new habit
  // completed perfectly for its first 3 days showed "10%" (3/30) instead
  // of the honest 100%, which reads as a failing habit right out of the
  // gate. Legacy habits saved before this field existed get a backfilled
  // date safely more than 30 days in the past (see
  // _fallbackOldHabitCreatedDate below) so their behavior doesn't change.
  final String createdDate;
  // Lets someone stop tracking a habit temporarily (a seasonal habit, a
  // planned break) without deleting it and losing its history — the only
  // option before this field existed. A paused habit is skipped by the
  // Dashboard's "what's left to do today" list and stops sending
  // reminders regardless of the per-habit reminder time or the global
  // Settings toggle, but its logs, streak, and completion-rate history
  // are untouched and still visible on the Habits screen.
  final bool paused;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.logs,
    this.reminderTime,
    required this.createdDate,
    this.paused = false,
  });

  Habit copyWith(
      {String? name,
      String? emoji,
      String? color,
      Map<String, bool>? logs,
      Object? reminderTime = _unset,
      String? createdDate,
      bool? paused}) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      logs: logs ?? this.logs,
      reminderTime: identical(reminderTime, _unset)
          ? this.reminderTime
          : reminderTime as String?,
      createdDate: createdDate ?? this.createdDate,
      paused: paused ?? this.paused,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color,
        'target': 'daily',
        'logs': {for (final k in logs.keys) k: true},
        if (reminderTime != null) 'reminderTime': reminderTime,
        'createdDate': createdDate,
        'paused': paused,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawLogs = (json['logs'] as Map?) ?? {};
    return Habit(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '🎯',
      color: (json['color'] as String?) ?? '#2196F3',
      logs: {for (final k in rawLogs.keys) k.toString(): true},
      reminderTime: json['reminderTime'] as String?,
      createdDate:
          (json['createdDate'] as String?) ?? _fallbackOldHabitCreatedDate(),
      paused: (json['paused'] as bool?) ?? false,
    );
  }
}

/// Backfill for habits saved before `createdDate` existed. 45 days back is
/// a safe margin past the 30-day completion-rate window, so a habit that
/// falls back to this date computes the exact same completion rate it
/// always has — this only changes behavior for habits created after this
/// field was added.
String _fallbackOldHabitCreatedDate() {
  final d = DateTime.now().subtract(const Duration(days: 45));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class NewHabit {
  final String name;
  final String emoji;
  final String color;
  final String? reminderTime;
  final String createdDate;
  const NewHabit(
      {required this.name,
      required this.emoji,
      required this.color,
      this.reminderTime,
      required this.createdDate});
}

class HabitWithStats {
  final Habit habit;
  final int streak;
  final int best;
  final int completionRate;
  final List<bool> last30;
  final List<bool> last7;
  // FEATURE (Analytics Feature 3 — "weekly-vs-monthly breakdown" and a
  // "missed-days count", the two gaps this card was missing): both
  // windows are age-aware the same way `completionRate` already is —
  // a habit created 3 days ago is judged against a 3-day window, not
  // artificially penalized against a 7- or 30-day one it couldn't
  // possibly have filled yet. Raw counts are exposed (not just a
  // percentage) so the UI can show "missed X of Y days" honestly
  // instead of back-computing an approximation from a rounded rate.
  final int weeklyRate;
  final int weeklyCompletedDays;
  final int weeklyWindowDays;
  final int monthlyCompletedDays;
  final int monthlyWindowDays;

  const HabitWithStats({
    required this.habit,
    required this.streak,
    required this.best,
    required this.completionRate,
    required this.last30,
    required this.last7,
    required this.weeklyRate,
    required this.weeklyCompletedDays,
    required this.weeklyWindowDays,
    required this.monthlyCompletedDays,
    required this.monthlyWindowDays,
  });

  String get id => habit.id;
  String get name => habit.name;
  String get emoji => habit.emoji;
  String get color => habit.color;
  bool get paused => habit.paused;
  Map<String, bool> get logs => habit.logs;
  int get missedThisWeek => weeklyWindowDays - weeklyCompletedDays;
  int get missedThisMonth => monthlyWindowDays - monthlyCompletedDays;
}

class FocusLogEntry {
  final String? taskId;
  final int minutes;
  final int at;

  const FocusLogEntry(
      {required this.taskId, required this.minutes, required this.at});

  Map<String, dynamic> toJson() =>
      {'taskId': taskId, 'minutes': minutes, 'at': at};

  factory FocusLogEntry.fromJson(Map<String, dynamic> json) => FocusLogEntry(
        taskId: json['taskId'] as String?,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
        at: (json['at'] as num?)?.toInt() ?? 0,
      );
}

class DailyReview {
  final int tasksCompleted;
  final int tasksTotal;
  final int focusMinutes;
  final int habitsCompleted;
  final int habitsTotal;
  final String wentWell;
  final String improve;
  final int savedAt;

  const DailyReview({
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.focusMinutes,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.wentWell,
    required this.improve,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'tasksCompleted': tasksCompleted,
        'tasksTotal': tasksTotal,
        'focusMinutes': focusMinutes,
        'habitsCompleted': habitsCompleted,
        'habitsTotal': habitsTotal,
        'wentWell': wentWell,
        'improve': improve,
        'savedAt': savedAt,
      };

  factory DailyReview.fromJson(Map<String, dynamic> json) => DailyReview(
        tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
        tasksTotal: (json['tasksTotal'] as num?)?.toInt() ?? 0,
        focusMinutes: (json['focusMinutes'] as num?)?.toInt() ?? 0,
        habitsCompleted: (json['habitsCompleted'] as num?)?.toInt() ?? 0,
        habitsTotal: (json['habitsTotal'] as num?)?.toInt() ?? 0,
        wentWell: (json['wentWell'] as String?) ?? '',
        improve: (json['improve'] as String?) ?? '',
        savedAt: (json['savedAt'] as num?)?.toInt() ?? 0,
      );
}

class UserSettings {
  final int pomodoroFocus;
  final int pomodoroBreak;
  final bool timeFormat24;
  final int weekStart;
  final bool notificationsEnabled;
  final bool taskRemindersEnabled;
  final bool habitRemindersEnabled;
  final bool dailyPlanningRemindersEnabled;
  final int dailyPlanningMorningHour;
  final int dailyPlanningEveningHour;

  // لغة التطبيق
  final String? languageCode;

  // اسم المستخدم (اختياري) — يُستخدم للترحيب الشخصي بالشاشة الرئيسية
  final String? userName;

  // هل أغلق المستخدم بانر "أضف اسمك" بالشاشة الرئيسية (يبقى مخفي دائمًا بعدها)
  final bool nameBannerDismissed;

  // قائمة التطبيقات المحظورة
  final List<String> blockedApps;

  const UserSettings({
    required this.pomodoroFocus,
    required this.pomodoroBreak,
    required this.timeFormat24,
    required this.weekStart,
    required this.notificationsEnabled,
    required this.taskRemindersEnabled,
    required this.habitRemindersEnabled,
    required this.dailyPlanningRemindersEnabled,
    required this.dailyPlanningMorningHour,
    required this.dailyPlanningEveningHour,
    this.languageCode,
    this.userName,
    this.nameBannerDismissed = false,
    this.blockedApps = const [],
  });

  UserSettings copyWith({
    int? pomodoroFocus,
    int? pomodoroBreak,
    bool? timeFormat24,
    int? weekStart,
    bool? notificationsEnabled,
    bool? taskRemindersEnabled,
    bool? habitRemindersEnabled,
    bool? dailyPlanningRemindersEnabled,
    int? dailyPlanningMorningHour,
    int? dailyPlanningEveningHour,
    Object? languageCode = _unset,
    Object? userName = _unset,
    bool? nameBannerDismissed,
    List<String>? blockedApps,
  }) {
    return UserSettings(
      pomodoroFocus: pomodoroFocus ?? this.pomodoroFocus,
      pomodoroBreak: pomodoroBreak ?? this.pomodoroBreak,
      timeFormat24: timeFormat24 ?? this.timeFormat24,
      weekStart: weekStart ?? this.weekStart,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      habitRemindersEnabled:
          habitRemindersEnabled ?? this.habitRemindersEnabled,
      dailyPlanningRemindersEnabled:
          dailyPlanningRemindersEnabled ?? this.dailyPlanningRemindersEnabled,
      dailyPlanningMorningHour:
          dailyPlanningMorningHour ?? this.dailyPlanningMorningHour,
      dailyPlanningEveningHour:
          dailyPlanningEveningHour ?? this.dailyPlanningEveningHour,
      languageCode: identical(languageCode, _unset)
          ? this.languageCode
          : languageCode as String?,
      userName: identical(userName, _unset)
          ? this.userName
          : userName as String?,
      nameBannerDismissed: nameBannerDismissed ?? this.nameBannerDismissed,
      blockedApps: blockedApps ?? this.blockedApps,
    );
  }

  Map<String, dynamic> toJson() => {
        'pomodoroFocus': pomodoroFocus,
        'pomodoroBreak': pomodoroBreak,
        'timeFormat24': timeFormat24,
        'weekStart': weekStart,
        'notificationsEnabled': notificationsEnabled,
        'taskRemindersEnabled': taskRemindersEnabled,
        'habitRemindersEnabled': habitRemindersEnabled,
        'dailyPlanningRemindersEnabled': dailyPlanningRemindersEnabled,
        'dailyPlanningMorningHour': dailyPlanningMorningHour,
        'dailyPlanningEveningHour': dailyPlanningEveningHour,
        if (languageCode != null) 'languageCode': languageCode,
        if (userName != null && userName!.trim().isNotEmpty)
          'userName': userName,
        'nameBannerDismissed': nameBannerDismissed,
        'blockedApps': blockedApps,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        pomodoroFocus: (json['pomodoroFocus'] as num?)?.toInt() ?? 25,
        pomodoroBreak: (json['pomodoroBreak'] as num?)?.toInt() ?? 5,
        timeFormat24: (json['timeFormat24'] as bool?) ?? false,
        weekStart: (json['weekStart'] as num?)?.toInt() ?? 1,
        notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
        taskRemindersEnabled: (json['taskRemindersEnabled'] as bool?) ?? false,
        habitRemindersEnabled:
            (json['habitRemindersEnabled'] as bool?) ?? false,
        dailyPlanningRemindersEnabled:
            (json['dailyPlanningRemindersEnabled'] as bool?) ?? false,
        dailyPlanningMorningHour:
            (json['dailyPlanningMorningHour'] as num?)?.toInt() ?? 8,
        dailyPlanningEveningHour:
            (json['dailyPlanningEveningHour'] as num?)?.toInt() ?? 20,
        languageCode: json['languageCode'] as String?,
        userName: json['userName'] as String?,
        nameBannerDismissed: (json['nameBannerDismissed'] as bool?) ?? false,
        blockedApps: (json['blockedApps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  static UserSettings defaults() => const UserSettings(
      pomodoroFocus: 25,
      pomodoroBreak: 5,
      timeFormat24: false,
      weekStart: 1,
      notificationsEnabled: true,
      taskRemindersEnabled: false,
      habitRemindersEnabled: false,
      dailyPlanningRemindersEnabled: false,
      dailyPlanningMorningHour: 8,
      dailyPlanningEveningHour: 20,
      languageCode: null,
      userName: null,
      nameBannerDismissed: false,
      blockedApps: []);
}

class DayStats {
  final int completed;
  final int total;
  final int skipped;
  final int actionable;
  final int pct;
  final int focusMinutes;
  final Task? nextTask;
  final int productivityScore;

  const DayStats({
    required this.completed,
    required this.total,
    required this.skipped,
    required this.actionable,
    required this.pct,
    required this.focusMinutes,
    required this.nextTask,
    required this.productivityScore,
  });

  static DayStats empty() => const DayStats(
        completed: 0,
        total: 0,
        skipped: 0,
        actionable: 0,
        pct: 0,
        focusMinutes: 0,
        nextTask: null,
        productivityScore: 0,
      );
}

class HistoryDay {
  final String date;
  final int totalTasks;
  final int completed;
  final int skipped;
  final int focusMinutes;

  const HistoryDay({
    required this.date,
    required this.totalTasks,
    required this.completed,
    required this.skipped,
    required this.focusMinutes,
  });
}

enum ToastKind { success, info, error }

class ToastState {
  final ToastKind kind;
  final String text;
  final String key;
  const ToastState({required this.kind, required this.text, required this.key});
}

class UserResource {
  final String id;
  final String title;
  final String? description;
  final String imagePath;
  final String url;
  final int createdAt;

  const UserResource({
    required this.id,
    required this.title,
    this.description,
    required this.imagePath,
    required this.url,
    required this.createdAt,
  });

  UserResource copyWith({
    String? title,
    String? description,
    String? imagePath,
    String? url,
  }) {
    return UserResource(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      url: url ?? this.url,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imagePath': imagePath,
        'url': url,
        'createdAt': createdAt,
      };

  factory UserResource.fromJson(Map<String, dynamic> json) => UserResource(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? 'Untitled',
        description: json['description'] as String?,
        imagePath: (json['imagePath'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class MeridianData {
  final int version;
  final List<Task> tasks;
  final List<Habit> habits;
  final List<UserResource> resources;
  final UserSettings settings;
  final List<FocusLogEntry> focusLog;
  final Map<String, DailyReview> reviews;

  const MeridianData({
    required this.version,
    required this.tasks,
    required this.habits,
    required this.resources,
    required this.settings,
    required this.focusLog,
    required this.reviews,
  });

  MeridianData copyWith({
    List<Task>? tasks,
    List<Habit>? habits,
    List<UserResource>? resources,
    UserSettings? settings,
    List<FocusLogEntry>? focusLog,
    Map<String, DailyReview>? reviews,
  }) {
    return MeridianData(
      version: version,
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      resources: resources ?? this.resources,
      settings: settings ?? this.settings,
      focusLog: focusLog ?? this.focusLog,
      reviews: reviews ?? this.reviews,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'resources': resources.map((r) => r.toJson()).toList(),
        'settings': settings.toJson(),
        'focusLog': focusLog.map((f) => f.toJson()).toList(),
        'reviews': {for (final e in reviews.entries) e.key: e.value.toJson()},
      };
}

const Object _unset = Object();
