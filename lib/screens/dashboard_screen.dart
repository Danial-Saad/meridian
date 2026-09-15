import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/dashboard/day_ring.dart';
import '../widgets/habits/habit_modal.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/field_label.dart';
import '../widgets/shared/mrd_bidi_text_field.dart';
import '../widgets/shared/mrd_checkbox.dart';
import '../widgets/shared/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onGoPlanner;
  final void Function(String taskId) onGoFocus;
  final VoidCallback onNew;
  final VoidCallback onOpenPlanDay;
  final VoidCallback onOpenReview;
  final VoidCallback onGoHabits;
  final VoidCallback onGoAnalytics;

  const DashboardScreen({
    super.key,
    required this.onGoPlanner,
    required this.onGoFocus,
    required this.onNew,
    required this.onOpenPlanDay,
    required this.onOpenReview,
    required this.onGoHabits,
    required this.onGoAnalytics,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // BUG FIX: the greeting ("Good morning"/"afternoon"/"evening"), the
    // date/time header, and the evening-only Day Review button were all
    // derived from a DateTime.now() captured once per build. If someone
    // left the dashboard open across a boundary — most commonly the 6pm
    // "evening" cutoff — none of it would update until something else
    // happened to trigger a rebuild (a task toggle, a tab switch). A
    // once-a-minute timer keeps it live without needing per-second
    // precision anywhere on this screen.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final now = DateTime.now();
    final stats = store.stats;
    final settings = store.settings;
    final l10n = AppLocalizations.of(context)!;

    // store.history is always exactly 28 entries, oldest -> newest, with
    // the last entry being today — so index 26 (length - 2) is yesterday.
    // Used only for the small trend indicators on the stat cards below;
    // the headline numbers themselves still come straight from `stats`.
    final yesterday = store.history[store.history.length - 2];
    final focusDelta = stats.focusMinutes - yesterday.focusMinutes;
    final scoreDelta = stats.productivityScore - _historyDayScore(yesterday);

    final upcoming = store.todaysTasks
        .where((t) =>
            t.status != TaskStatus.completed && t.status != TaskStatus.skipped)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final upcomingTop = upcoming.take(4).toList();

    // Priority order instead of raw storage order: habits not yet done
    // today surface first (most useful thing to act on right now), and
    // among those, the ones with the longest active streak come first —
    // those are exactly the ones with the most to lose if today gets
    // skipped. Habits already checked off today sink toward the bottom
    // (and past the fold into "+N more" first, if there's overflow),
    // since there's nothing left to do on them right now.
    final todayKey = dayKey(now);
    final sortedHabits = store.habits.where((h) => !h.paused).toList()
      ..sort((a, b) {
        final aDone = a.logs[todayKey] == true;
        final bDone = b.logs[todayKey] == true;
        if (aDone != bDone) return aDone ? 1 : -1;
        if (!aDone) return b.streak.compareTo(a.streak);
        return 0;
      });
    final habitsOverflow = sortedHabits.length > 4;
    final habitsToday =
        sortedHabits.take(habitsOverflow ? 3 : 4).toList();
    final isEveningish = now.hour >= 18;
    final userName = settings.userName?.trim();
    final hasName = userName != null && userName.isNotEmpty;
    final greeting = now.hour < 12
        ? (hasName ? l10n.greetingMorningNamed(userName) : l10n.greetingMorning)
        : now.hour < 18
            ? (hasName
                ? l10n.greetingAfternoonNamed(userName)
                : l10n.greetingAfternoon)
            : (hasName
                ? l10n.greetingEveningNamed(userName)
                : l10n.greetingEvening);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('${fmtDate(now, l10n)} · ${fmtClock(now, l10n, settings.timeFormat24)}',
            style: TextStyle(
                fontSize: 12, color: c.textFaint, fontFamily: 'monospace')),
        const SizedBox(height: 6),
        Text(greeting,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 4),
        Text(isEveningish ? l10n.dashboardSubtitleEvening : l10n.dashboardSubtitleDay,
            style: TextStyle(fontSize: 14, color: c.textDim)),
        if (!hasName && !settings.nameBannerDismissed) ...[
          const SizedBox(height: 14),
          _NameBanner(
            c: c,
            onAdd: () => _showQuickNameDialog(context, store),
            onDismiss: () => store
                .updateSettings((s) => s.copyWith(nameBannerDismissed: true)),
          ),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onOpenPlanDay,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.textDim,
                side: BorderSide(color: c.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: Text(l10n.planMyDay,
                  style:
                      const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
          if (isEveningish) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onOpenReview,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.primary,
                  side: BorderSide(color: c.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(l10n.dayReviewButton,
                    style:
                        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 20),
        MeridianDayRingCard(tasks: store.todaysTasks, stats: stats),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: StatCard(
                  label: l10n.focusTimeLabel,
                  value:
                      '${stats.focusMinutes ~/ 60}h ${stats.focusMinutes % 60}m',
                  icon: Icons.local_fire_department,
                  onTap: widget.onGoAnalytics,
                  trendText: l10n.trendVsYesterday('${_signed(focusDelta)}m'),
                  trendUp: focusDelta == 0 ? null : focusDelta > 0)),
          const SizedBox(width: 12),
          Expanded(
              child: StatCard(
                  label: l10n.scoreLabel,
                  value: '${stats.productivityScore}',
                  icon: Icons.trending_up,
                  onTap: widget.onGoAnalytics,
                  trendText: l10n.trendVsYesterday(_signed(scoreDelta)),
                  trendUp: scoreDelta == 0 ? null : scoreDelta > 0)),
        ]),
        const SizedBox(height: 22),
        if (stats.nextTask != null)
          _NextTaskCard(
              task: stats.nextTask!, settings: settings, onGoFocus: widget.onGoFocus)
        else
          EmptyState(
              title: l10n.dashboardClearTitle,
              subtitle: l10n.dashboardClearSubtitle,
              actionLabel: l10n.createTaskButton,
              onAction: widget.onNew),
        const SizedBox(height: 22),
        _SectionHeader(
            title: l10n.todaysScheduleTitle,
            actionLabel: l10n.openPlannerButton,
            onAction: widget.onGoPlanner,
            c: c),
        if (upcomingTop.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.scheduleEmptyText,
                style: TextStyle(fontSize: 13, color: c.textFaint)),
          )
        else ...[
          ...upcomingTop.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MiniTaskRow(
                    task: t,
                    settings: settings,
                    onToggle: () => store.toggleTaskComplete(t.id)),
              )),
          // Was previously silently truncated to 4 with no way to know
          // more existed. Only the count beyond what's already visible
          // here — not the full upcoming count — so it reads as "N more
          // beyond what you're looking at", not a duplicate total.
          if (upcoming.length > upcomingTop.length)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: InkWell(
                onTap: widget.onGoPlanner,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                      l10n.moreItemsLabel(upcoming.length - upcomingTop.length),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: c.textFaint,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
        const SizedBox(height: 22),
        _SectionHeader(
            title: l10n.habitsTitle,
            actionLabel: l10n.viewAllLabel,
            onAction: widget.onGoHabits,
            c: c),
        if (habitsToday.isEmpty)
          EmptyState(
            title: l10n.habitsEmptyTitle,
            subtitle: l10n.habitsEmptySubtitle,
            actionLabel: l10n.addHabitButton,
            onAction: () =>
                showHabitModal(context, onSave: store.addHabit),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              ...habitsToday.map((h) => _MiniHabitCard(
                    habit: h,
                    onTap: () => store.toggleHabitToday(h.id),
                  )),
              // Keeps a clean 2x2 grid (3 real cards + this one) instead
              // of silently hiding habits past the 4th with no trace, or
              // spilling into a lopsided 5-item grid.
              if (habitsOverflow)
                _MoreHabitsCard(
                  count: sortedHabits.length - habitsToday.length,
                  onTap: widget.onGoHabits,
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MeridianColors c;
  const _SectionHeader(
      {required this.title, this.actionLabel, this.onAction, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w600, color: c.text)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  foregroundColor: c.textDim, padding: EdgeInsets.zero),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(actionLabel!, style: const TextStyle(fontSize: 12.5)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward, size: 12),
              ]),
            ),
        ],
      ),
    );
  }
}

class _NextTaskCard extends StatelessWidget {
  final Task task;
  final UserSettings settings;
  final void Function(String taskId) onGoFocus;
  const _NextTaskCard(
      {required this.task, required this.settings, required this.onGoFocus});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    // stats.nextTask (which feeds this card) is already scoped to today
    // and already excludes completed/skipped tasks, so a start time in
    // the past here can only mean one thing: the task's window opened
    // and nobody acted on it yet.
    final isOverdue = task.start < nowMinutes;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(
            color: isOverdue ? c.danger.withValues(alpha: 0.45) : c.border),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [c.surface, c.bgElevated]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
                l10n.upNextLabel(
                    minutesToLabel(task.start, l10n, settings.timeFormat24),
                    minutesToLabel(task.start + task.duration, l10n,
                        settings.timeFormat24)),
                style: TextStyle(
                    fontSize: 11, color: c.textFaint, letterSpacing: 0.5)),
            if (isOverdue) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(l10n.overdueBadge,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: c.danger)),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 14),
          Row(children: [
            if (task.link != null) ...[
              OutlinedButton(
                onPressed: () => launchUrl(Uri.parse(task.link!),
                    mode: LaunchMode.externalApplication),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textDim,
                  side: BorderSide(color: c.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.open_in_new, size: 15),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onGoFocus(task.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.primaryInk,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: Text(l10n.startFocusButton,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                label: const Icon(Icons.arrow_forward, size: 15),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  final Task task;
  final UserSettings settings;
  final VoidCallback onToggle;
  const _MiniTaskRow(
      {required this.task, required this.settings, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final completed = task.status == TaskStatus.completed;
    final catColor = kCategories[task.category]?.color ?? c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
          color: c.bgElevated),
      child: Row(children: [
        MrdCheckbox(checked: completed, onTap: onToggle),
        const SizedBox(width: 10),
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? c.textFaint : c.text,
              )),
        ),
        const SizedBox(width: 8),
        Text(minutesToLabel(task.start, l10n, settings.timeFormat24),
            style: TextStyle(
                fontSize: 11, color: c.textFaint, fontFamily: 'monospace')),
      ]),
    );
  }
}

class _MiniHabitCard extends StatelessWidget {
  final HabitWithStats habit;
  final VoidCallback onTap;
  const _MiniHabitCard({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final doneToday = habit.logs[dayKey(DateTime.now())] == true;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 17)),
                if (doneToday) Icon(Icons.check, size: 13, color: c.success),
              ]),
              Text(habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
              Row(children: [
                Icon(Icons.local_fire_department,
                    size: 11,
                    color: habit.streak > 0 ? c.warning : c.textFaint),
                const SizedBox(width: 4),
                Text(l10n.habitStreakDays(habit.streak),
                    style: TextStyle(fontSize: 10.5, color: c.textFaint)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreHabitsCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MoreHabitsCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: c.textDim),
              const SizedBox(height: 4),
              Text(l10n.moreItemsLabel(count),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textDim)),
            ],
          ),
        ),
      ),
    );
  }
}

// Lightweight, one-field dialog behind the dismissible "add your name"
// banner — filling it in is the fastest path (no navigating away to
// Settings), and it's also reachable any time later from the Profile
// section in Settings if someone skips it here.
void _showQuickNameDialog(BuildContext context, MeridianStore store) {
  final l10n = AppLocalizations.of(context)!;
  final c = context.read<ThemeController>().colors;
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: c.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.whatShouldWeCallYouTitle,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
        content: MrdBidiTextField(
          controller: ctrl,
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: mrdInputDecoration(c, hint: l10n.yourNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: TextButton.styleFrom(foregroundColor: c.textDim),
            child: Text(l10n.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                store.updateSettings((s) => s.copyWith(userName: name));
              }
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: c.primary, foregroundColor: c.primaryInk),
            child: Text(l10n.saveLabel),
          ),
        ],
      );
    },
  );
}

// Deliberately quiet: same border/surface language as every other card on
// this screen (no accent color, no icon-in-a-circle, no shadow) so it
// reads as a small, optional nudge rather than an interruption — and it
// only ever renders once (Dashboard already hides it once a name is set
// or the person taps "No thanks").
class _NameBanner extends StatelessWidget {
  final MeridianColors c;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const _NameBanner(
      {required this.c, required this.onAdd, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.waving_hand_outlined, size: 15, color: c.textFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.addNameBannerText,
                style: TextStyle(fontSize: 12, color: c.textDim),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: c.primary,
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.addWord,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: l10n.noThanksLabel,
            icon: Icon(Icons.close, size: 15, color: c.textFaint),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

// Same formula as _computeStats' productivityScore in meridian_store.dart,
// applied to a historical day so "vs yesterday" compares like with like.
// Kept in sync manually since HistoryDay doesn't store a precomputed
// score of its own.
int _historyDayScore(HistoryDay d) {
  final actionable = d.totalTasks - d.skipped;
  if (actionable <= 0) return 0;
  return clampInt(
    (((d.completed / actionable) * 70) +
            ((d.focusMinutes / 240).clamp(0, 1) * 30))
        .round(),
    0,
    100,
  );
}

String _signed(int n) => n >= 0 ? '+$n' : '$n';
