import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../constants.dart';

class DelayAnalysisCard extends StatelessWidget {
  // UI/UX FIX (self-review, requested to make this genuinely perfect):
  // this card used to read `store.tasks` directly — *every* task ever
  // created, completely ignoring the Today/Week/Month toggle that
  // governs every other card on this screen. Exactly the same
  // "Discrepancy #4" class of bug already found and fixed for the
  // top-level Productivity Score and Category Distribution earlier in
  // this project — it just never got propagated to this card (or, on
  // inspection, to Features 3/4/5's cards either, which take the same
  // zero parameters this one used to). Now takes the same
  // `rangeDayKeys`/`rangeLabel` the rest of the screen already computes,
  // so switching the toggle actually changes what this card shows too.
  final Set<String> rangeDayKeys;
  final String rangeLabel;

  const DelayAnalysisCard(
      {super.key, required this.rangeDayKeys, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;
    final allTasks = store.tasks;

    // "Currently overdue" is deliberately its own thing, not filtered by
    // the range toggle: it's a real-time, actionable question ("what
    // needs attention right now") rather than a historical one, so it
    // stays constant across Today/Week/Month the same way a live alert
    // would. Only `todo`/`inProgress` count — a `skipped` task is a
    // resolved outcome the person deliberately chose, not something
    // still needing attention, even if its date has passed.
    final todayKey = dayKey(DateTime.now());
    final currentlyOverdue = allTasks
        .where((t) =>
            (t.status == TaskStatus.todo || t.status == TaskStatus.inProgress) &&
            t.taskDate.compareTo(todayKey) < 0)
        .length;

    // 1. استخراج المهام التي تم تأجيلها (postponedCount > 0)، بحدود
    // الفترة المختارة (Today/Week/Month) — انظر التعليق فوق.
    final delayedTasks = allTasks
        .where((t) => t.postponedCount > 0 && rangeDayKeys.contains(t.taskDate))
        .toList();
    final totalDelayed = delayedTasks.length;

    // 2. حساب الفئة (Category) الأكثر تأجيلاً + توزيع كامل لكل الفئات
    final categoryCounts = <TaskCategory, int>{};
    int maxDelay = 0;
    TaskCategory? mostDelayedCategory;

    for (final t in delayedTasks) {
      categoryCounts[t.category] =
          (categoryCounts[t.category] ?? 0) + t.postponedCount;
      if (categoryCounts[t.category]! > maxDelay) {
        maxDelay = categoryCounts[t.category]!;
        mostDelayedCategory = t.category;
      }
    }

    // FEATURE (Analytics Feature 2 — closing the two gaps this row
    // documented: "no delay amount" and no fuller pattern beyond a
    // single "most delayed" headline. `originalDate` (see domain.dart)
    // is set the first time a task is ever postponed and never touched
    // again, so the gap between it and wherever `taskDate` currently
    // sits is the *total* delay accumulated across every reschedule —
    // computed here, not stored, since it changes every day a
    // still-delayed task remains unresolved.
    final delaysInDays = delayedTasks
        .where((t) => t.originalDate != null)
        .map((t) =>
            parseDayKey(t.taskDate).difference(parseDayKey(t.originalDate!)).inDays)
        .where((d) => d > 0)
        .toList();
    final avgDelayDays = delaysInDays.isEmpty
        ? 0.0
        : delaysInDays.reduce((a, b) => a + b) / delaysInDays.length;

    // Priority breakdown — same shape as the category one above, using
    // data that already existed (priority + postponedCount), no schema
    // change needed for this half of the upgrade.
    final priorityCounts = <TaskPriority, int>{};
    for (final t in delayedTasks) {
      priorityCounts[t.priority] = (priorityCounts[t.priority] ?? 0) + t.postponedCount;
    }

    // إذا لم يكن هناك مهام مؤجلة بالفترة المختارة
    if (totalDelayed == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16),
            color: c.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.taskDelaysTitle,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
            const SizedBox(height: 2),
            Text(l10n.noPostponedTasksSubtitle,
                style: TextStyle(fontSize: 11.5, color: c.textFaint)),
            if (currentlyOverdue > 0) ...[
              const SizedBox(height: 12),
              _OverdueBanner(c: c, count: currentlyOverdue, l10n: l10n),
            ],
          ],
        ),
      );
    }

    final catInfo =
        mostDelayedCategory != null ? kCategories[mostDelayedCategory] : null;

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedPriorities = priorityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategoryCount = sortedCategories.isEmpty ? 1 : sortedCategories.first.value;
    final maxPriorityCount = sortedPriorities.isEmpty ? 1 : sortedPriorities.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16),
          color: c.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.taskDelaysTitle,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text('${l10n.patternsInPostponedTasks} · $rangeLabel',
              style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          if (currentlyOverdue > 0) ...[
            const SizedBox(height: 12),
            _OverdueBanner(c: c, count: currentlyOverdue, l10n: l10n),
          ],
          const SizedBox(height: 14),
          // IntrinsicHeight: with three tiles now instead of two, a
          // longer translated label (or a wider category name) can wrap
          // to a second line in one tile but not the others — Text
          // itself handles that fine (grows the tile, doesn't overflow
          // or clip anything), but left alone the three tiles would end
          // up visibly uneven heights. This keeps them matched.
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    c: c,
                    label: l10n.delayedTasksLabel,
                    value: '$totalDelayed',
                    icon: Icons.history_toggle_off,
                    iconColor: c.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    c: c,
                    label: l10n.mostDelayedLabel,
                    value: mostDelayedCategory != null
                        ? categoryLabel(context, mostDelayedCategory)
                        : '-',
                    icon: Icons.category_outlined,
                    iconColor: catInfo?.color ?? c.textDim,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    c: c,
                    label: l10n.averageDelayDaysLabel,
                    value: delaysInDays.isEmpty
                        ? '-'
                        : avgDelayDays.toStringAsFixed(1),
                    icon: Icons.timelapse_outlined,
                    iconColor: c.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 14),
          Text(l10n.byCategoryLabel,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.textFaint,
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          ...sortedCategories.map((e) => _DelayBar(
                c: c,
                label: categoryLabel(context, e.key),
                count: e.value,
                maxCount: maxCategoryCount,
                color: kCategories[e.key]?.color ?? c.primary,
              )),
          const SizedBox(height: 14),
          Text(l10n.byPriorityLabel,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.textFaint,
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          ...sortedPriorities.map((e) => _DelayBar(
                c: c,
                label: priorityLabel(context, e.key),
                count: e.value,
                maxCount: maxPriorityCount,
                color: kPriorities[e.key]?.color ?? c.primary,
              )),
        ],
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final MeridianColors c;
  final int count;
  final AppLocalizations l10n;

  const _OverdueBanner(
      {required this.c, required this.count, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: c.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.currentlyOverdueLabel(count),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.danger)),
          ),
        ],
      ),
    );
  }
}

class _DelayBar extends StatelessWidget {
  final MeridianColors c;
  final String label;
  final int count;
  final int maxCount;
  final Color color;

  const _DelayBar({
    required this.c,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount <= 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: c.textDim)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: c.bgElevated,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text('$count',
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final MeridianColors c;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _InfoTile(
      {required this.c,
      required this.label,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: c.textDim)),
        ],
      ),
    );
  }
}
