import '../models/domain.dart';
import '../utils/format_utils.dart';

// FIX (GHADI_DEVELOPMENT.md, "Notes / Discrepancies Found", #3): this used
// to only count completed-task planned duration toward a day's
// focusMinutes, silently dropping real Focus Mode session minutes
// (`FocusLogEntry`) for every day except "today" — which reaches
// `DayStats` through a *different* code path in `meridian_store.dart`
// (`_computeStats`) that already added them. Week/Month Analytics could
// therefore under-report focus time relative to what Today showed, and
// any "planned vs actual time" comparison built on top of it would have
// been comparing planned time against a number that wasn't actually
// "actual." `_buildDay` below now matches `_computeStats`'s formula
// exactly: completed-task duration credit, plus real logged session
// minutes for that day.
HistoryDay _buildDay(String date, List<Task>? tasksForDay, int sessionMinutes) {
  final tasks = tasksForDay ?? const <Task>[];
  final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
  final skipped = tasks.where((t) => t.status == TaskStatus.skipped).length;
  final focusFromTasks = tasks
      .where((t) => t.status == TaskStatus.completed)
      .fold<int>(0, (sum, t) => sum + t.duration);
  return HistoryDay(
    date: date,
    totalTasks: tasks.length,
    completed: completed,
    skipped: skipped,
    focusMinutes: focusFromTasks + sessionMinutes,
  );
}

List<HistoryDay> buildHistory(List<Task> allTasks, List<FocusLogEntry> focusLog) {
  final today = DateTime.now();
  final byDate = <String, List<Task>>{};
  for (final t in allTasks) {
    byDate.putIfAbsent(t.taskDate, () => []).add(t);
  }
  final sessionMinutesByDate = <String, int>{};
  for (final f in focusLog) {
    final key = dayKey(DateTime.fromMillisecondsSinceEpoch(f.at));
    sessionMinutesByDate[key] = (sessionMinutesByDate[key] ?? 0) + f.minutes;
  }

  final days = <HistoryDay>[];
  for (var i = 27; i >= 0; i--) {
    final d = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: i));
    final key = dayKey(d);
    days.add(_buildDay(key, byDate[key], sessionMinutesByDate[key] ?? 0));
  }
  return days;
}
