import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../analysis/analytics_charts.dart';
import '../analysis/delay_analysis.dart';
import '../analysis/habit_analysis.dart';
import '../analysis/pattern_analysis.dart';
import '../analysis/insights_analysis.dart';
import '../widgets/shared/buttons.dart';
import '../widgets/shared/stat_card.dart';

enum _Range { today, week, month }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final tasks = store.tasks;
    final history = store.history;
    final habits = store.habits;
    final l10n = AppLocalizations.of(context)!;

    // BUG FIX: "This week" used to always mean a fixed rolling 7 days,
    // completely ignoring the "Week starts on" setting in Settings even
    // though that setting's own description promises it "Affects weekly
    // views and reviews." Now computed as the actual current calendar
    // week so far, starting from whichever day (Sunday or Monday) is
    // configured, so changing that setting has a real, visible effect
    // here — the one place in the app it was always meant to apply to.
    final weekStartSetting = store.settings.weekStart; // 0 = Sunday, 1 = Monday
    final todayWeekday = DateTime.now().weekday; // 1 = Monday ... 7 = Sunday
    final daysSinceWeekStart = weekStartSetting == 1
        ? todayWeekday - 1
        : todayWeekday % 7;
    final weekWindowLength = daysSinceWeekStart + 1; // inclusive of today

    final slice = _range == _Range.today
        ? history.sublist(history.length - 1)
        : _range == _Range.week
            ? history.sublist(history.length - weekWindowLength)
            : history.sublist(history.length - 28);

    final totalTasks = slice.fold<int>(0, (s, d) => s + d.totalTasks);
    final completed = slice.fold<int>(0, (s, d) => s + d.completed);
    final skippedTasks = slice.fold<int>(0, (s, d) => s + d.skipped);
    final focusMinutes = slice.fold<int>(0, (s, d) => s + d.focusMinutes);
    final completionRate =
        totalTasks > 0 ? ((completed / totalTasks) * 100).round() : 0;
    final avgSession = completed > 0 ? (focusMinutes / completed).round() : 0;

    // FIX (GHADI_DEVELOPMENT.md, "Notes / Discrepancies Found", #4): the
    // "Productivity score" stat card used to always show *today's* score
    // (`store.stats.productivityScore`, a today-only DayStats field),
    // regardless of the Today/Week/Month toggle above it — so switching
    // to Week or Month changed every other number on the screen except
    // this one. Recomputed here from the same `slice` as everything else,
    // using the same weighted formula as `_computeStats` (70% completion
    // of actionable tasks + 30% focus-time-vs-target), with the 240
    // min/day target scaled by how many days are actually in the range so
    // Week/Month aren't unfairly held to a single day's target.
    final actionableTasks = totalTasks - skippedTasks;
    final focusTarget = 240 * (slice.isEmpty ? 1 : slice.length);
    final productivityScore = actionableTasks > 0
        ? clampInt(
            (((completed / actionableTasks) * 70) +
                    ((focusMinutes / focusTarget).clamp(0, 1) * 30))
                .round(),
            0,
            100,
          )
        : 0;

    // Range-aware date window, reused below for the category chart and for
    // Feature 1's "planned vs actual time" — the exact same days `slice`
    // itself covers, so every number on this screen agrees on what
    // "this week" / "this month" means.
    final rangeDayKeys = slice.map((d) => d.date).toSet();
    final rangeLabel = _range == _Range.today
        ? l10n.todayWord
        : _range == _Range.week
            ? l10n.thisWeekSoFarLabel
            : l10n.last28DaysLabel;
    final plannedMinutes = tasks
        .where((t) => rangeDayKeys.contains(t.taskDate))
        .fold<int>(0, (s, t) => s + t.duration);

    // --- FEATURE 1: Advanced Productivity Calculation ---
    int habitConsistency = 0;
    if (habits.isNotEmpty) {
      if (_range == _Range.today) {
        final todayKey = dayKey(DateTime.now());
        int doneToday = habits.where((h) => h.logs[todayKey] == true).length;
        habitConsistency = ((doneToday / habits.length) * 100).round();
      } else if (_range == _Range.week) {
        // h.last7 is the same fixed rolling-7-days window as the old
        // "This week" — recompute directly from logs over the same
        // calendar-aligned window as `slice` above instead, so habit
        // consistency and the task/focus stats above always agree on
        // what "this week" means.
        final weekDayKeys = List.generate(weekWindowLength, (i) {
          final d = DateTime.now().subtract(Duration(days: weekWindowLength - 1 - i));
          return dayKey(DateTime(d.year, d.month, d.day));
        });
        int done = habits.fold<int>(
            0,
            (s, h) =>
                s + weekDayKeys.where((k) => h.logs[k] == true).length);
        habitConsistency =
            ((done / (habits.length * weekWindowLength)) * 100).round();
      } else {
        int done =
            habits.fold<int>(0, (s, h) => s + h.last30.where((b) => b).length);
        habitConsistency = ((done / (habits.length * 30)) * 100).round();
      }
    }
    // ----------------------------------------------------

    // FIX (GHADI_DEVELOPMENT.md, "Notes / Discrepancies Found", #4):
    // "Category distribution" used to always aggregate every task ever
    // created, completely ignoring the Today/Week/Month toggle. Now
    // scoped to `rangeDayKeys`, the same window the rest of the screen
    // uses — switching the toggle actually changes what this chart shows.
    final rangeTasks =
        tasks.where((t) => rangeDayKeys.contains(t.taskDate)).toList();
    final counts = <String, int>{};
    for (final t in rangeTasks) {
      counts[t.category.name] = (counts[t.category.name] ?? 0) + 1;
    }
    final total = rangeTasks.isEmpty ? 1 : rangeTasks.length;
    final categoryDist = kCategories.entries
        .map((e) => CategoryDatum(
              id: e.key.name,
              label: categoryLabel(context, e.key),
              color: e.value.color,
              count: counts[e.key.name] ?? 0,
              pct: (((counts[e.key.name] ?? 0) / total) * 100).round(),
            ))
        .where((d) => d.count > 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(l10n.analyticsTitle,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 4),
        Text(l10n.analyticsSubtitle,
            style: TextStyle(fontSize: 13, color: c.textDim)),
        const SizedBox(height: 16),
        Row(children: [
          MrdPill(
              active: _range == _Range.today,
              onTap: () => setState(() => _range = _Range.today),
              label: l10n.todayWord),
          const SizedBox(width: 8),
          MrdPill(
              active: _range == _Range.week,
              onTap: () => setState(() => _range = _Range.week),
              label: l10n.thisWeekFilter),
          const SizedBox(width: 8),
          MrdPill(
              active: _range == _Range.month,
              onTap: () => setState(() => _range = _Range.month),
              label: l10n.thisMonthFilter),
        ]),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatCard(
                label: l10n.productivityScoreLabel,
                value: '$productivityScore',
                icon: Icons.flash_on),
            StatCard(
                label: l10n.focusTimeLabel,
                value: '${focusMinutes ~/ 60}h ${focusMinutes % 60}m',
                icon: Icons.local_fire_department),
            StatCard(
                label: l10n.completionRateLabel,
                value: '$completionRate%',
                icon: Icons.percent),
            StatCard(
                label: l10n.avgSessionLabel,
                value: '${avgSession}m',
                icon: Icons.access_time),
          ],
        ),
        const SizedBox(height: 20),

        // --- FEATURE 1: Execution & Consistency Card ---
        ChartCard(
          title: l10n.executionConsistencyTitle,
          subtitle: l10n.executionConsistencySubtitle,
          child: AdvancedProgressOverview(
            completed: completed,
            total: totalTasks,
            habitConsistency: habitConsistency,
            plannedMinutes: plannedMinutes,
            actualMinutes: focusMinutes,
          ),
        ),
        const SizedBox(height: 16),
        // ------------------------------------------------

        // --- FEATURE 2: Task Delay Analysis ---
        DelayAnalysisCard(rangeDayKeys: rangeDayKeys, rangeLabel: rangeLabel),
        const SizedBox(height: 16),
        // --------------------------------------

        // --- FEATURE 3: Habit Commitment Analysis ---
        HabitCommitmentCard(
            useWeeklyView: _range != _Range.month, rangeLabel: rangeLabel),
        const SizedBox(height: 16),
        // --------------------------------------------

        // --- FEATURE 4: Productivity Pattern Analysis ---
        ProductivityPatternCard(rangeDayKeys: rangeDayKeys, rangeLabel: rangeLabel),
        const SizedBox(height: 16),
        // ----------------------------------------------

        // --- FEATURE 5: Productivity Insights ---
        const ProductivityInsightsCard(),
        const SizedBox(height: 16),
        // -----------------------------------------

        ChartCard(
          title: l10n.focusTimeTrendTitle,
          subtitle: _range == _Range.today
              ? l10n.todaysFocusBySession
              : l10n.minutesPerDayLabel(_range == _Range.week ? l10n.thisWeekSoFarLabel : l10n.last28DaysLabel),
          child: _range == _Range.today
              ? TodayFocusBreakdown(minutes: focusMinutes)
              : FocusAreaChart(data: slice),
        ),
        const SizedBox(height: 16),
        ChartCard(
            title: l10n.categoryDistributionTitle,
            subtitle: l10n.categoryBreakdownRangeLabel(rangeLabel),
            child: DonutChart(data: categoryDist)),
        const SizedBox(height: 16),
        ChartCard(
            title: l10n.completedVsSkippedTitle,
            subtitle: l10n.dailyBreakdownLabel,
            child: CompletionBarChart(data: slice)),
        const SizedBox(height: 16),
        ChartCard(
            title: l10n.thisWeekFilter,
            subtitle: l10n.habitCompletionLabel,
            child: WeeklyHabitStrip(habits: habits)),
      ],
    );
  }
}
