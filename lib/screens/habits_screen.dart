import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/habits/habit_modal.dart';
import '../widgets/shared/buttons.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/empty_state.dart';

/// Ported from HabitsScreen.tsx. Single-column card list on mobile instead
/// of the desktop's auto-fill grid (min 260px) — a phone width only ever
/// fits one card per row anyway, so the grid collapses naturally.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final habits = store.habits;
    final activeHabits = habits.where((h) => !h.paused).toList();
    final pausedHabits = habits.where((h) => h.paused).toList();
    final todayKey = dayKey(DateTime.now());
    final l10n = AppLocalizations.of(context)!;

    void requestDelete(HabitWithStats h) {
      showMrdConfirm(
        context,
        title: l10n.habitDeleteTitle,
        description: h.streak > 0
            ? l10n.habitDeleteDescStreak(h.name, h.streak)
            : l10n.habitDeleteDescHistory(h.name),
        confirmLabel: l10n.deleteLabel,
        onConfirm: () => store.deleteHabit(h.id),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showHabitModal(context, onSave: store.addHabit),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(l10n.habitsTitle,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 4),
          Text(l10n.habitsSubtitle,
              style: TextStyle(fontSize: 13, color: c.textDim)),
          const SizedBox(height: 20),
          if (habits.isEmpty)
            EmptyState(
              title: l10n.habitsEmptyTitle,
              subtitle: l10n.habitsEmptySubtitle,
              actionLabel: l10n.addHabitButton,
              onAction: () => showHabitModal(context, onSave: store.addHabit),
              icon: Icons.local_fire_department,
            )
          else
            ...activeHabits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _HabitCard(
                    habit: h,
                    doneToday: h.logs[todayKey] == true,
                    onToggle: () => store.toggleHabitToday(h.id),
                    onPauseToggle: () => store.toggleHabitPaused(h.id),
                    onEdit: () => showHabitModal(
                      context,
                      habit: h.habit,
                      onSave: (data) => store.updateHabit(
                          h.id,
                          (habit) => habit.copyWith(
                              name: data.name,
                              emoji: data.emoji,
                              color: data.color,
                              reminderTime: data.reminderTime)),
                      onDelete: () {
                        Navigator.of(context).pop();
                        requestDelete(h);
                      },
                    ),
                    onDelete: () => requestDelete(h),
                  ),
                )),
          if (pausedHabits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.pausedHabitsTitle,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: c.textFaint)),
            const SizedBox(height: 12),
            ...pausedHabits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Opacity(
                    opacity: 0.6,
                    child: _HabitCard(
                      habit: h,
                      doneToday: h.logs[todayKey] == true,
                      onToggle: () => store.toggleHabitToday(h.id),
                      onPauseToggle: () => store.toggleHabitPaused(h.id),
                      onEdit: () => showHabitModal(
                        context,
                        habit: h.habit,
                        onSave: (data) => store.updateHabit(
                            h.id,
                            (habit) => habit.copyWith(
                                name: data.name,
                                emoji: data.emoji,
                                color: data.color,
                                reminderTime: data.reminderTime)),
                        onDelete: () {
                          Navigator.of(context).pop();
                          requestDelete(h);
                        },
                      ),
                      onDelete: () => requestDelete(h),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitWithStats habit;
  final bool doneToday;
  final VoidCallback onToggle;
  final VoidCallback onPauseToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.doneToday,
    required this.onToggle,
    required this.onPauseToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final color = hexToColor(habit.color);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16),
          color: c.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: c.text)),
                    Text(l10n.dailyLabel,
                        style: TextStyle(fontSize: 11, color: c.textFaint)),
                  ],
                ),
              ),
              MrdIconOnlyButton(
                  onTap: onEdit,
                  icon: Icons.edit_outlined,
                  label: l10n.editLabel,
                  size: 13),
              const SizedBox(width: 8), // UI FIX (audit report #8): see MrdIconOnlyButton's own comment — keeps expanded tap targets from overlapping.
              MrdIconOnlyButton(
                  onTap: onPauseToggle,
                  icon: habit.paused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  label: habit.paused
                      ? l10n.resumeButtonLabel
                      : l10n.pauseHabitLabel,
                  size: 13),
              const SizedBox(width: 8),
              MrdIconOnlyButton(
                  onTap: onDelete,
                  icon: Icons.delete_outline,
                  label: l10n.deleteLabel,
                  size: 13,
                  danger: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _MiniStat(
                    icon: Icons.local_fire_department,
                    value: '${habit.streak}',
                    label: l10n.streakLabel,
                    color: habit.streak > 0 ? c.warning : null)),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStat(
                    icon: Icons.emoji_events_outlined,
                    value: '${habit.best}',
                    label: l10n.bestLabel)),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStat(
                    icon: Icons.percent,
                    value: '${habit.completionRate}%',
                    label: l10n.day30Label)),
          ]),
          const SizedBox(height: 14),
          _HabitHeatmap(last30: habit.last30, color: color),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onToggle,
            style: OutlinedButton.styleFrom(
              foregroundColor: doneToday ? c.success : c.textDim,
              side: BorderSide(color: doneToday ? c.success : c.border),
              backgroundColor: doneToday
                  ? c.success.withValues(alpha: 0.14)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check, size: 14),
            label: Text(
                doneToday ? l10n.doneTodayLabel : l10n.markDoneTodayLabel,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  const _MiniStat(
      {required this.icon,
      required this.value,
      required this.label,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: c.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, size: 13, color: color ?? c.textFaint),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
        Text(label,
            style:
                TextStyle(fontSize: 9, color: c.textFaint, letterSpacing: 0.4)),
      ]),
    );
  }
}

/// 30-day heatmap: 10 columns x 3 rows, opacity ramps slightly toward today
/// (matching the original's "streak momentum" gradient rather than a flat
/// GitHub-style grid).
class _HabitHeatmap extends StatelessWidget {
  final List<bool> last30;
  final Color color;
  const _HabitHeatmap({required this.last30, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: last30.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemBuilder: (context, i) {
            final done = last30[i];
            final opacity = done ? 0.55 + (i / last30.length) * 0.45 : 1.0;
            return Container(
              decoration: BoxDecoration(
                color: done ? color.withValues(alpha: opacity) : c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.daysAgo30Label,
                style: TextStyle(fontSize: 9.5, color: c.textFaint)),
            Text(l10n.todayWord,
                style: TextStyle(fontSize: 9.5, color: c.textFaint)),
          ],
        ),
      ],
    );
  }
}
