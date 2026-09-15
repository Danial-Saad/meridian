import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'models/domain.dart';

class CategoryInfo {
  final String label;
  final Color color;
  // Redundant with `color` on purpose — task blocks on the Planner grid
  // are color-coded by category with no text label (not enough room),
  // so relying on color alone to tell categories apart isn't usable for
  // colorblind users. A distinct icon per category is a second,
  // shape-based cue that works even if the colors themselves don't read
  // as different.
  final IconData icon;
  const CategoryInfo(this.label, this.color, this.icon);
}

class PriorityInfo {
  final String label;
  final Color color;
  const PriorityInfo(this.label, this.color);
}

/// Category colors, ported verbatim from constants.ts (which itself is
/// ported verbatim from the approved prototype's tokens). Deliberately
/// distinct from the accent blue so tasks stay visually distinguishable
/// from brand chrome on the Planner and Day Ring.
const Map<TaskCategory, CategoryInfo> kCategories = {
  TaskCategory.study:
      CategoryInfo('Study', Color(0xFF8B5CF6), Icons.school_outlined),
  TaskCategory.work:
      CategoryInfo('Work', Color(0xFF0EA5A4), Icons.work_outline),
  TaskCategory.personal:
      CategoryInfo('Personal', Color(0xFF4ADE80), Icons.person_outline),
  TaskCategory.health:
      CategoryInfo('Health', Color(0xFFF5A623), Icons.favorite_outline),
  TaskCategory.project:
      CategoryInfo('Project', Color(0xFFF0596A), Icons.rocket_launch_outlined),
};

const Map<TaskPriority, PriorityInfo> kPriorities = {
  TaskPriority.low: PriorityInfo('Low', Color(0xFF57576D)),
  TaskPriority.medium: PriorityInfo('Medium', Color(0xFF0EA5A4)),
  TaskPriority.high: PriorityInfo('High', Color(0xFFF5A623)),
  TaskPriority.urgent: PriorityInfo('Urgent', Color(0xFFF0596A)),
};

class TaskStatusOption {
  final TaskStatus id;
  final String label;
  const TaskStatusOption(this.id, this.label);
}

const kTaskStatuses = [
  TaskStatusOption(TaskStatus.todo, 'To do'),
  TaskStatusOption(TaskStatus.inProgress, 'In progress'),
  TaskStatusOption(TaskStatus.completed, 'Completed'),
  TaskStatusOption(TaskStatus.skipped, 'Skipped'),
];

const kHabitEmojis = [
  '💪',
  '📚',
  '💧',
  '📖',
  '🧘',
  '🏃',
  '🎯',
  '🎨',
  '🛌',
  '🥗',
  '✍️',
  '🎸'
];
const kHabitColors = [
  Color(0xFF2196F3),
  Color(0xFF0D47A1),
  Color(0xFF4ADE80),
  Color(0xFFF5A623),
  Color(0xFFF0596A),
  Color(0xFF8B5CF6),
];

/// Localized display label for a task category. `kCategories[cat]!.color`
/// still supplies the color; use this instead of `.label` anywhere the
/// label is shown to the user.
String categoryLabel(BuildContext context, TaskCategory cat) {
  final l10n = AppLocalizations.of(context)!;
  switch (cat) {
    case TaskCategory.study:
      return l10n.categoryStudy;
    case TaskCategory.work:
      return l10n.categoryWork;
    case TaskCategory.personal:
      return l10n.categoryPersonal;
    case TaskCategory.health:
      return l10n.categoryHealth;
    case TaskCategory.project:
      return l10n.categoryProject;
  }
}

/// Localized display label for a task priority. `kPriorities[pri]!.color`
/// still supplies the color; use this instead of `.label` anywhere the
/// label is shown to the user.
String priorityLabel(BuildContext context, TaskPriority pri) {
  final l10n = AppLocalizations.of(context)!;
  switch (pri) {
    case TaskPriority.low:
      return l10n.priorityLow;
    case TaskPriority.medium:
      return l10n.priorityMedium;
    case TaskPriority.high:
      return l10n.priorityHigh;
    case TaskPriority.urgent:
      return l10n.priorityUrgent;
  }
}

/// Localized display label for a task status — use instead of
/// `kTaskStatuses`' `.label` anywhere the label is shown to the user.
String taskStatusLabel(BuildContext context, TaskStatus status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case TaskStatus.todo:
      return l10n.statusTodo;
    case TaskStatus.inProgress:
      return l10n.statusInProgress;
    case TaskStatus.completed:
      return l10n.statusCompleted;
    case TaskStatus.skipped:
      return l10n.statusSkipped;
  }
}

String colorToHex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

Color hexToColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}
