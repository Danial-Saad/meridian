import '../models/domain.dart';
import '../utils/format_utils.dart';
import 'persistence.dart';

/// Demo data ported from seed.ts. Deliberately opt-in only (loaded from a
/// Settings action), never shown automatically — a genuinely empty first
/// load is a normal, honest state for a local-first app.
List<Task> seedTasks() {
  final today = dayKey(DateTime.now());
  final raw = <Map<String, dynamic>>[
    {
      'title': 'Deep Work — Computer Architecture',
      'category': TaskCategory.study,
      'priority': TaskPriority.high,
      'status': TaskStatus.completed,
      'start': 9 * 60,
      'duration': 90
    },
    {
      'title': 'Lecture review — Lecture 7 memory hierarchy',
      'category': TaskCategory.study,
      'priority': TaskPriority.medium,
      'status': TaskStatus.completed,
      'start': 10 * 60 + 30,
      'duration': 60
    },
    {
      'title': 'Lunch',
      'category': TaskCategory.personal,
      'priority': TaskPriority.low,
      'status': TaskStatus.completed,
      'start': 12 * 60,
      'duration': 45
    },
    {
      'title': 'Probability & Statistics — problem set',
      'category': TaskCategory.study,
      'priority': TaskPriority.high,
      'status': TaskStatus.inProgress,
      'start': 13 * 60,
      'duration': 90
    },
    {
      'title': 'Quick call — project teammate',
      'category': TaskCategory.project,
      'priority': TaskPriority.low,
      'status': TaskStatus.todo,
      'start': 14 * 60,
      'duration': 30
    },
    {
      'title': 'Workout',
      'category': TaskCategory.health,
      'priority': TaskPriority.medium,
      'status': TaskStatus.todo,
      'start': 15 * 60,
      'duration': 60
    },
    {
      'title': 'NodaCurve — bug triage',
      'category': TaskCategory.project,
      'priority': TaskPriority.urgent,
      'status': TaskStatus.todo,
      'start': 16 * 60 + 30,
      'duration': 75
    },
    {
      'title': 'Grocery run',
      'category': TaskCategory.personal,
      'priority': TaskPriority.low,
      'status': TaskStatus.todo,
      'start': 18 * 60,
      'duration': 40
    },
    {
      'title': 'Digital Communications — Module 8 notes',
      'category': TaskCategory.study,
      'priority': TaskPriority.medium,
      'status': TaskStatus.todo,
      'start': 19 * 60,
      'duration': 60
    },
    {
      'title': 'Wind down — reading',
      'category': TaskCategory.personal,
      'priority': TaskPriority.low,
      'status': TaskStatus.todo,
      'start': 21 * 60 + 30,
      'duration': 30
    },
  ];
  return raw
      .map((t) => Task(
            id: uid(),
            title: t['title'] as String,
            category: t['category'] as TaskCategory,
            priority: t['priority'] as TaskPriority,
            status: t['status'] as TaskStatus,
            start: t['start'] as int,
            duration: t['duration'] as int,
            notes: '',
            taskDate: today,
          ))
      .toList();
}

Map<String, bool> _mkLogs(List<int> pattern) {
  final today = DateTime.now();
  final logs = <String, bool>{};
  for (var i = 0; i < pattern.length; i++) {
    final d = today.subtract(Duration(days: pattern.length - 1 - i));
    if (pattern[i] != 0) logs[dayKey(d)] = true;
  }
  return logs;
}

List<Habit> seedHabits() {
  final specs = <List<dynamic>>[
    [
      'Workout',
      '💪',
      '#f5a623',
      [
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1
      ]
    ],
    [
      'Study block',
      '📚',
      '#8B5CF6',
      [
        1,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ]
    ],
    [
      'Water intake',
      '💧',
      '#2196F3',
      [
        1,
        0,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        1,
        1,
        1,
        0
      ]
    ],
    [
      'Reading',
      '📖',
      '#4ade80',
      [
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0
      ]
    ],
    [
      'Meditation',
      '🧘',
      '#f0596a',
      [
        1,
        1,
        1,
        0,
        0,
        1,
        1,
        1,
        1,
        0,
        1,
        1,
        0,
        1,
        1,
        1,
        0,
        1,
        1,
        0,
        1,
        1,
        1,
        0,
        1,
        1,
        0,
        1,
        1
      ]
    ],
  ];
  return specs
      .map((s) => Habit(
            id: uid(),
            name: s[0] as String,
            emoji: s[1] as String,
            color: s[2] as String,
            logs: _mkLogs(List<int>.from(s[3] as List)),
            // Demo habits are meant to look like established, long-running
            // habits (that's the whole point of the seeded 30-day history),
            // so backdate creation well past the completion-rate window —
            // same reasoning as _fallbackOldHabitCreatedDate in domain.dart.
            createdDate: dayKey(DateTime.now().subtract(const Duration(days: 45))),
          ))
      .toList();
}

MeridianData seedData() => MeridianData(
      version: kMeridianDataVersion,
      tasks: seedTasks(),
      habits: seedHabits(),
      resources: const [],
      settings: UserSettings.defaults(),
      focusLog: const [],
      reviews: const {},
    );
