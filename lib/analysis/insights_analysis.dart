import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';

/// FEATURE 5: Productivity Insights.
///
/// Features 1/3/4 each report on one signal at a time (execution, habit
/// commitment, or time/day patterns). This card looks *across* those
/// signals for connections none of them surface alone: a week-over-week
/// trend, a normally-solid habit that's gone quiet, whether the user's
/// best focus hours actually line up with when they schedule work, and
/// urgent tasks that are still open after already being postponed.
/// Everything is computed locally from data already in the store — no
/// network access, consistent with the rest of the app.
enum _Tone { positive, warning, info }

class _Insight {
  final IconData icon;
  final String text;
  final _Tone tone;
  const _Insight(this.icon, this.text, this.tone);
}

class ProductivityInsightsCard extends StatelessWidget {
  const ProductivityInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;
    final insights = _buildInsights(store, l10n);

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
          Text(l10n.productivityInsightsTitle,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(l10n.whatRecentActivitySuggests,
              style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          const SizedBox(height: 14),
          if (insights.isEmpty)
            Text(
              l10n.keepUsingMeridianInsight,
              style:
                  TextStyle(fontSize: 12.5, color: c.textFaint, height: 1.35),
            )
          else
            Column(
              children: [
                for (var i = 0; i < insights.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _InsightRow(c: c, insight: insights[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<_Insight> _buildInsights(MeridianStore store, AppLocalizations l10n) {
    final insights = <_Insight>[];

    // --- Rule 1: week-over-week completion-rate trend ---
    // store.history is always exactly 28 entries, oldest -> newest, with
    // the last entry being today (see store/history.dart).
    final history = store.history;
    final thisWeek = history.sublist(21);
    final lastWeek = history.sublist(14, 21);
    final thisTotal = thisWeek.fold<int>(0, (s, d) => s + d.totalTasks);
    final thisDone = thisWeek.fold<int>(0, (s, d) => s + d.completed);
    final lastTotal = lastWeek.fold<int>(0, (s, d) => s + d.totalTasks);
    final lastDone = lastWeek.fold<int>(0, (s, d) => s + d.completed);
    // Require a small minimum of real activity in both windows so this
    // isn't just noise from comparing two nearly-empty weeks.
    if (thisTotal >= 3 && lastTotal >= 3) {
      final thisRate = (thisDone / thisTotal) * 100;
      final lastRate = (lastDone / lastTotal) * 100;
      final diff = (thisRate - lastRate).round();
      if (diff >= 5) {
        insights.add(_Insight(
          Icons.trending_up,
          l10n.completionUpInsight(diff),
          _Tone.positive,
        ));
      } else if (diff <= -5) {
        insights.add(_Insight(
          Icons.trending_down,
          l10n.completionDownInsight(-diff),
          _Tone.warning,
        ));
      } else {
        insights.add(_Insight(
          Icons.trending_flat,
          l10n.completionSteadyInsight(thisRate.round()),
          _Tone.info,
        ));
      }
    }

    final habits = store.habits;
    if (habits.isNotEmpty) {
      // --- Rule 2: best active habit streak ---
      final byStreak = List<HabitWithStats>.from(habits)
        ..sort((a, b) => b.streak.compareTo(a.streak));
      final topStreak = byStreak.first;
      if (topStreak.streak >= 3) {
        insights.add(_Insight(
          Icons.local_fire_department,
          l10n.strongestHabitStreak(
              topStreak.emoji, topStreak.name, topStreak.streak),
          _Tone.positive,
        ));
      }

      // --- Rule 3: a normally-reliable habit that's gone quiet ---
      // Different signal from Feature 3's "Needs Attention" (which flags
      // low overall completion): this flags a habit with decent overall
      // history whose *current* streak has just broken.
      final lapsed = List<HabitWithStats>.from(habits)
        ..removeWhere((h) => h.streak != 0 || h.completionRate < 40)
        ..sort((a, b) => b.completionRate.compareTo(a.completionRate));
      if (lapsed.isNotEmpty) {
        final h = lapsed.first;
        insights.add(_Insight(
          Icons.notifications_active_outlined,
          l10n.lapsedHabitInsight(h.emoji, h.name, h.completionRate),
          _Tone.warning,
        ));
      }
    }

    // --- Rule 4: does peak focus time line up with when tasks get done? ---
    final focusLog = store.focusLog;
    if (focusLog.length >= 3) {
      final focusMinutesByBucket = <String, int>{
        'Morning': 0,
        'Afternoon': 0,
        'Evening': 0,
        'Night': 0,
      };
      for (final f in focusLog) {
        final bucket =
            _bucketForHour(DateTime.fromMillisecondsSinceEpoch(f.at).hour);
        focusMinutesByBucket[bucket] =
            (focusMinutesByBucket[bucket] ?? 0) + f.minutes;
      }
      final bestFocusBucket =
          focusMinutesByBucket.entries.reduce((a, b) => a.value >= b.value ? a : b);

      final completedTasks =
          store.tasks.where((t) => t.status == TaskStatus.completed).toList();
      if (bestFocusBucket.value > 0 && completedTasks.length >= 3) {
        final taskCountByBucket = <String, int>{
          'Morning': 0,
          'Afternoon': 0,
          'Evening': 0,
          'Night': 0,
        };
        for (final t in completedTasks) {
          final bucket = _bucketForHour(t.start ~/ 60);
          taskCountByBucket[bucket] = (taskCountByBucket[bucket] ?? 0) + 1;
        }
        final bestTaskBucket =
            taskCountByBucket.entries.reduce((a, b) => a.value >= b.value ? a : b);

        if (bestTaskBucket.value > 0) {
          if (bestFocusBucket.key == bestTaskBucket.key) {
            insights.add(_Insight(
              Icons.check_circle_outline,
              l10n.goodAlignmentInsight(
                  _bucketLabelLower(bestTaskBucket.key, l10n)),
              _Tone.positive,
            ));
          } else {
            insights.add(_Insight(
              Icons.schedule_outlined,
              l10n.misalignedFocusInsight(
                  _bucketLabelLower(bestFocusBucket.key, l10n),
                  _bucketLabelLower(bestTaskBucket.key, l10n)),
              _Tone.info,
            ));
          }
        }
      }
    }

    // --- Rule 5: urgent tasks still open after already being postponed ---
    final slippingUrgent = store.tasks
        .where((t) =>
            t.priority == TaskPriority.urgent &&
            t.postponedCount > 0 &&
            (t.status == TaskStatus.todo || t.status == TaskStatus.inProgress))
        .toList();
    if (slippingUrgent.isNotEmpty) {
      final first = slippingUrgent.first;
      final extra = slippingUrgent.length - 1;
      insights.add(_Insight(
        Icons.flag_outlined,
        extra > 0
            ? l10n.urgentTasksPostponedPlural(first.title, extra,
                extra == 1 ? l10n.urgentTaskWordSingular : l10n.urgentTaskWordPlural)
            : l10n.urgentTaskPostponedSingular(first.title),
        _Tone.warning,
      ));
    }

    return insights;
  }

  String _bucketLabelLower(String bucket, AppLocalizations l10n) {
    switch (bucket) {
      case 'Morning':
        return l10n.periodMorningLower;
      case 'Afternoon':
        return l10n.periodAfternoonLower;
      case 'Evening':
        return l10n.periodEveningLower;
      default:
        return l10n.periodNightLower;
    }
  }

  String _bucketForHour(int hour) {
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 22) return 'Evening';
    return 'Night';
  }
}

class _InsightRow extends StatelessWidget {
  final MeridianColors c;
  final _Insight insight;
  const _InsightRow({required this.c, required this.insight});

  Color _colorFor(_Tone tone) {
    switch (tone) {
      case _Tone.positive:
        return c.success;
      case _Tone.warning:
        return c.warning;
      case _Tone.info:
        return c.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(insight.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(insight.icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(insight.text,
                style: TextStyle(fontSize: 13, color: c.text, height: 1.35)),
          ),
        ),
      ],
    );
  }
}
