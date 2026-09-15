import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class ProductivityPatternCard extends StatelessWidget {
  // UI/UX FIX (self-review, same check already applied to Feature 2):
  // this card took zero parameters and ignored the Today/Week/Month
  // toggle entirely for two of its three patterns. Not a blind
  // find-and-replace of the Feature 2 fix, though — the "best day of
  // the week" pattern is a fundamentally different kind of question,
  // and forcing it to respect a single-day or single-week range would
  // break its own premise (you can't compare "which weekday is best"
  // from one occurrence of one weekday). See the per-pattern comments
  // below for what actually changed and why the weekly pattern
  // deliberately didn't.
  final Set<String> rangeDayKeys;
  final String rangeLabel;

  const ProductivityPatternCard(
      {super.key, required this.rangeDayKeys, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;

    // 1. Focus Pattern Analysis (تحليل أوقات التركيز)
    // FIX: was `store.focusLog` — every session ever logged, regardless
    // of the selected range. Filtered to the range's day-keys, same as
    // the rest of this screen. Also added a minimum-minutes floor
    // before calling something a "peak": one 5-minute session winning
    // by default because it's the only session logged isn't a pattern,
    // it's a single data point being overclaimed as one.
    const minPeakMinutes = 30;
    String focusPattern = l10n.notEnoughFocusData;
    final rangeFocusLog = store.focusLog
        .where((log) => rangeDayKeys
            .contains(dayKey(DateTime.fromMillisecondsSinceEpoch(log.at))))
        .toList();
    if (rangeFocusLog.isNotEmpty) {
      int morning = 0, afternoon = 0, evening = 0, night = 0;
      for (var log in rangeFocusLog) {
        final dt = DateTime.fromMillisecondsSinceEpoch(log.at);
        final hour = dt.hour;
        if (hour >= 6 && hour < 12) {
          morning += log.minutes;
        } else if (hour >= 12 && hour < 17) {
          afternoon += log.minutes;
        } else if (hour >= 17 && hour < 22) {
          evening += log.minutes;
        } else {
          night += log.minutes;
        }
      }

      int maxFocus = morning;
      String bestTime = l10n.periodMorning;
      if (afternoon > maxFocus) {
        maxFocus = afternoon;
        bestTime = l10n.periodAfternoon;
      }
      if (evening > maxFocus) {
        maxFocus = evening;
        bestTime = l10n.periodEvening;
      }
      if (night > maxFocus) {
        maxFocus = night;
        bestTime = l10n.periodNight;
      }

      if (maxFocus >= minPeakMinutes) {
        focusPattern =
            '${l10n.peakFocusOccurs(bestTime, maxFocus)} · $rangeLabel';
      }
    }

    // 2. Weekly Pattern Analysis (تحليل أفضل أيام الأسبوع)
    // Deliberately NOT filtered by rangeDayKeys — see the class-level
    // comment above. Always looks at the same rolling `store.history`
    // window regardless of the Today/Week/Month toggle, and says so
    // explicitly in its own sentence so it's not confusing why this one
    // pattern doesn't move when the toggle changes while the other two
    // do.
    //
    // FIX: also switched `DateTime.parse(day.date)` (which needed its
    // own try/catch as a hedge against a format `store.history` can
    // actually never produce, since it's always built from `dayKey()`
    // internally) to the shared `parseDayKey()` already used everywhere
    // else in this codebase for exactly this string shape — one fewer
    // one-off parsing path, no functional difference for well-formed
    // input, no try/catch needed since parseDayKey doesn't throw.
    //
    // FIX: added a minimum-occurrences floor per candidate weekday
    // (>= 2). Without it, a weekday that only appears once in the
    // history — say, one single Tuesday at a lucky 100% — could win
    // outright over a day with ten occurrences at a real, representative
    // 85%, which is a statistically weak claim dressed up as a
    // confident one.
    const minWeekdayOccurrences = 2;
    String weeklyPattern = l10n.notEnoughDailyReviews;
    if (store.history.length >= 3) {
      final completedByDay = <int, int>{};
      final totalByDay = <int, int>{};
      final occurrencesByDay = <int, int>{};

      for (var day in store.history) {
        final dt = parseDayKey(day.date);
        completedByDay[dt.weekday] =
            (completedByDay[dt.weekday] ?? 0) + day.completed;
        totalByDay[dt.weekday] = (totalByDay[dt.weekday] ?? 0) + day.totalTasks;
        occurrencesByDay[dt.weekday] = (occurrencesByDay[dt.weekday] ?? 0) + 1;
      }

      int bestDay = 1;
      double bestRate = -1.0;
      completedByDay.forEach((day, comp) {
        final tot = totalByDay[day] ?? 0;
        final occurrences = occurrencesByDay[day] ?? 0;
        if (tot > 0 && occurrences >= minWeekdayOccurrences) {
          final rate = comp / tot;
          if (rate > bestRate) {
            bestRate = rate;
            bestDay = day;
          }
        }
      });

      if (bestRate >= 0) {
        final weekdays = [
          l10n.dayNameMondayInSentence,
          l10n.dayNameTuesdayInSentence,
          l10n.dayNameWednesdayInSentence,
          l10n.dayNameThursdayInSentence,
          l10n.dayNameFridayInSentence,
          l10n.dayNameSaturdayInSentence,
          l10n.dayNameSundayInSentence,
        ];
        final dayName = weekdays[bestDay - 1];
        weeklyPattern =
            '${l10n.highestCompletionRateDay(dayName, (bestRate * 100).round())} · ${l10n.last28DaysLabel}';
      }
    }

    // 3. Delay Pattern Analysis (تحليل تأجيل المهام حسب الأولوية)
    // FIX: filtered to the selected range, same reasoning as Feature 2's
    // equivalent fix. Also added a minimum-postponements floor (>= 2)
    // before naming a priority level as "frequently" postponed — a
    // single task pushed back once isn't a frequency, it's an instance.
    const minDelayOccurrences = 2;
    String delayPattern = l10n.noTasksPostponed;
    final delayedTasks = store.tasks
        .where((t) => t.postponedCount > 0 && rangeDayKeys.contains(t.taskDate))
        .toList();
    if (delayedTasks.isNotEmpty) {
      final delaysByPriority = <TaskPriority, int>{};
      for (var t in delayedTasks) {
        delaysByPriority[t.priority] =
            (delaysByPriority[t.priority] ?? 0) + t.postponedCount;
      }

      TaskPriority? mostDelayed;
      int maxD = 0;
      delaysByPriority.forEach((p, count) {
        if (count > maxD && count >= minDelayOccurrences) {
          maxD = count;
          mostDelayed = p;
        }
      });

      if (mostDelayed != null) {
        delayPattern =
            '${l10n.postponingPriorityTasks(priorityLabel(context, mostDelayed!), maxD)} · $rangeLabel';
      }
    }

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
          Text(l10n.productivityPatternsTitle,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(l10n.observedBehavioralTrends,
              style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          const SizedBox(height: 16),
          _PatternItem(c: c, icon: Icons.schedule, text: focusPattern),
          const SizedBox(height: 12),
          _PatternItem(c: c, icon: Icons.calendar_today, text: weeklyPattern),
          const SizedBox(height: 12),
          _PatternItem(c: c, icon: Icons.update, text: delayPattern),
        ],
      ),
    );
  }
}

class _PatternItem extends StatelessWidget {
  final MeridianColors c;
  final IconData icon;
  final String text;

  const _PatternItem({required this.c, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c.textDim),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: c.text, height: 1.3)),
        ),
      ],
    );
  }
}
