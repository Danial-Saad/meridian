import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';

class HabitCommitmentCard extends StatelessWidget {
  // UI/UX FIX (self-review — same check already applied to Features 2
  // and 4): the "Most Consistent" / "Needs Attention" ranking always
  // used `completionRate`, a fixed ~30-day window, no matter what the
  // Today/Week/Month toggle above this card was set to. Not the same
  // fix as Feature 2's, though — `HabitWithStats` already carries both
  // a `weeklyRate` and a monthly `completionRate` as two genuinely
  // separate, independently-computed windows (not a single list that
  // can be re-filtered by day-key the way tasks can), so "respecting
  // the toggle" here means picking *which already-computed window* to
  // rank by, not re-deriving a new one. A single "Today" doesn't have
  // its own meaningful consistency window (one day isn't a consistency
  // measure), so Today and Week both use the weekly figure — the
  // closest genuinely-computed match — and only Month switches to the
  // monthly one.
  final bool useWeeklyView;
  final String rangeLabel;

  const HabitCommitmentCard(
      {super.key, required this.useWeeklyView, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;
    final habits = store.habits;

    if (habits.isEmpty) {
      return _buildEmptyState(c, l10n);
    }

    int rateOf(HabitWithStats h) => useWeeklyView ? h.weeklyRate : h.completionRate;

    // ترتيب العادات تنازلياً حسب نسبة الإنجاز بالفترة المختارة
    var sortedHabits = List<HabitWithStats>.from(habits)
      ..sort((a, b) => rateOf(b).compareTo(rateOf(a)));

    HabitWithStats? bestHabit =
        sortedHabits.isNotEmpty ? sortedHabits.first : null;
    HabitWithStats? needsAttention;

    // تحديد العادة التي تحتاج اهتماماً (أقل نسبة إنجاز، بشرط أن تكون أقل من 50%)
    if (sortedHabits.length > 1 && rateOf(sortedHabits.last) < 50) {
      needsAttention = sortedHabits.last;
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
          Text(l10n.habitCommitmentTitle,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text('${l10n.habitCommitmentSubtitle} · $rangeLabel',
              style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          const SizedBox(height: 14),
          Row(
            children: [
              if (bestHabit != null)
                Expanded(
                  child: _InfoTile(
                    c: c,
                    label: l10n.mostConsistentLabel,
                    value: '${bestHabit.habit.emoji} ${bestHabit.habit.name}',
                    subValue: l10n.overallPctLabel(rateOf(bestHabit)),
                    indicatorColor: c.success,
                  ),
                ),
              if (bestHabit != null && needsAttention != null)
                const SizedBox(width: 10),
              if (needsAttention != null)
                Expanded(
                  child: _InfoTile(
                    c: c,
                    label: l10n.needsAttentionLabel,
                    value:
                        '${needsAttention.habit.emoji} ${needsAttention.habit.name}',
                    subValue: l10n.overallPctLabel(rateOf(needsAttention)),
                    indicatorColor: c.danger,
                  ),
                ),
            ],
          ),
          // FEATURE (Analytics Feature 3 — closing the two gaps this card
          // was missing: a weekly-vs-monthly breakdown, and a
          // missed-days count. Both computed age-aware in
          // `_computeHabitStats` — see `HabitWithStats`'s new fields —
          // so a brand-new habit isn't unfairly scored against a window
          // longer than it's actually existed for.
          const SizedBox(height: 18),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 14),
          Text(l10n.perHabitBreakdownLabel,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.textFaint,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          ...sortedHabits
              .map((h) => _HabitBreakdownRow(c: c, l10n: l10n, stats: h)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MeridianColors c, AppLocalizations l10n) {
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
          Text(l10n.habitCommitmentTitle,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(l10n.addHabitsToSeePatterns,
              style: TextStyle(fontSize: 11.5, color: c.textFaint)),
        ],
      ),
    );
  }
}

class _HabitBreakdownRow extends StatelessWidget {
  final MeridianColors c;
  final AppLocalizations l10n;
  final HabitWithStats stats;

  const _HabitBreakdownRow(
      {required this.c, required this.l10n, required this.stats});

  Color _rateColor(int rate) {
    if (rate >= 80) return c.success;
    if (rate >= 50) return c.warning;
    return c.danger;
  }

  @override
  Widget build(BuildContext context) {
    // UI FIX: an earlier draft of this row put the two rate pills on the
    // *same* row as the emoji + habit name, competing for horizontal
    // space. Arabic and Russian's "this week"/"this month" translations
    // both run noticeably longer than the English ones — exactly the
    // kind of fixed-row-width squeeze that caused a real overflow bug
    // elsewhere in this app (the Planner's task blocks). Giving the
    // stats their own full-width row below the name, using `Wrap`
    // instead of a plain `Row`, means a long translation degrades by
    // wrapping to a second line rather than overflowing the card.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(stats.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(stats.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: stats.paused ? c.textFaint : c.text)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            // RTL fix: this indents the stats row to sit under the habit
            // name (past the emoji), which is on the *start* edge in
            // both directions — `EdgeInsets.only(left:)` would indent on
            // the wrong side in an Arabic (RTL) layout.
            padding: const EdgeInsetsDirectional.only(start: 23),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _RateStat(
                    c: c,
                    label: l10n.thisWeekFilter,
                    rate: stats.weeklyRate,
                    color: _rateColor(stats.weeklyRate)),
                _RateStat(
                    c: c,
                    label: l10n.thisMonthFilter,
                    rate: stats.completionRate,
                    color: _rateColor(stats.completionRate)),
                if (stats.missedThisMonth > 0)
                  Text(
                      l10n.missedDaysLabel(
                          stats.missedThisMonth, stats.monthlyWindowDays),
                      style: TextStyle(fontSize: 10.5, color: c.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateStat extends StatelessWidget {
  final MeridianColors c;
  final String label;
  final int rate;
  final Color color;

  const _RateStat(
      {required this.c,
      required this.label,
      required this.rate,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$rate%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10.5, color: c.textFaint)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final MeridianColors c;
  final String label;
  final String value;
  final String subValue;
  final Color indicatorColor;

  const _InfoTile({
    required this.c,
    required this.label,
    required this.value,
    required this.subValue,
    required this.indicatorColor,
  });

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: indicatorColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, color: c.textDim)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subValue, style: TextStyle(fontSize: 11.5, color: c.textFaint)),
        ],
      ),
    );
  }
}
