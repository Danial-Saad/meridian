import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/shared/buttons.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/field_label.dart';
import '../widgets/shared/mrd_bidi_text_field.dart';
import '../widgets/shared/mrd_checkbox.dart';
import '../widgets/tasks/task_modal.dart';

enum _StatusFilter { all, open, completed, skipped }
enum _DateFilter { all, today, upcoming, past }

/// Ported from TasksScreen.tsx, including its date-scope filter (today's
/// list is no longer implicitly "all tasks" once tasks carry a real date).
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _StatusFilter _filter = _StatusFilter.all;
  TaskCategory? _catFilter; // null = all categories
  _DateFilter _dateFilter = _DateFilter.all;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final tasks = store.tasks;
    final settings = store.settings;
    final todayKey = dayKey(DateTime.now());
    final l10n = AppLocalizations.of(context)!;

    var filtered = tasks.where((t) {
      switch (_filter) {
        case _StatusFilter.all:
          return true;
        case _StatusFilter.completed:
          return t.status == TaskStatus.completed;
        case _StatusFilter.skipped:
          return t.status == TaskStatus.skipped;
        case _StatusFilter.open:
          return t.status != TaskStatus.completed && t.status != TaskStatus.skipped;
      }
    }).where((t) => _catFilter == null || t.category == _catFilter).where((t) {
      switch (_dateFilter) {
        case _DateFilter.all:
          return true;
        case _DateFilter.today:
          return t.taskDate == todayKey;
        case _DateFilter.upcoming:
          return t.taskDate.compareTo(todayKey) > 0;
        case _DateFilter.past:
          return t.taskDate.compareTo(todayKey) < 0;
      }
    }).toList()
      ..sort((a, b) => a.taskDate == b.taskDate ? a.start.compareTo(b.start) : a.taskDate.compareTo(b.taskDate));

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) => t.title.toLowerCase().contains(query)).toList();
    }

    final skippedCount = tasks.where((t) => t.status == TaskStatus.skipped).length;
    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context, store, todayKey, settings),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(l10n.tasksTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 4),
          Text(l10n.tasksSummary(tasks.length, completedCount), style: TextStyle(fontSize: 13, color: c.textDim)),
          const SizedBox(height: 12),
          MrdBidiTextField(
            controller: _searchCtrl,
            style: TextStyle(color: c.text, fontSize: 13.5),
            decoration: mrdInputDecoration(c, hint: l10n.searchTasksHint).copyWith(
              prefixIcon: Icon(Icons.search, size: 18, color: c.textFaint),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 16, color: c.textFaint),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                MrdPill(active: _dateFilter == _DateFilter.all, onTap: () => setState(() => _dateFilter = _DateFilter.all), label: l10n.anyDateFilter),
                const SizedBox(width: 8),
                MrdPill(active: _dateFilter == _DateFilter.today, onTap: () => setState(() => _dateFilter = _DateFilter.today), label: l10n.todayWord),
                const SizedBox(width: 8),
                MrdPill(active: _dateFilter == _DateFilter.upcoming, onTap: () => setState(() => _dateFilter = _DateFilter.upcoming), label: l10n.upcomingFilter),
                const SizedBox(width: 8),
                MrdPill(active: _dateFilter == _DateFilter.past, onTap: () => setState(() => _dateFilter = _DateFilter.past), label: l10n.pastFilter),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                MrdPill(active: _filter == _StatusFilter.all, onTap: () => setState(() => _filter = _StatusFilter.all), label: l10n.allFilter),
                const SizedBox(width: 8),
                MrdPill(active: _filter == _StatusFilter.open, onTap: () => setState(() => _filter = _StatusFilter.open), label: l10n.openFilter),
                const SizedBox(width: 8),
                MrdPill(active: _filter == _StatusFilter.completed, onTap: () => setState(() => _filter = _StatusFilter.completed), label: l10n.statusCompleted),
                if (skippedCount > 0) ...[
                  const SizedBox(width: 8),
                  MrdPill(active: _filter == _StatusFilter.skipped, onTap: () => setState(() => _filter = _StatusFilter.skipped), label: l10n.statusSkipped),
                ],
                const SizedBox(width: 8),
                Container(width: 1, color: c.border),
                const SizedBox(width: 8),
                MrdPill(active: _catFilter == null, onTap: () => setState(() => _catFilter = null), label: l10n.allCategoriesFilter),
                ...kCategories.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: MrdPill(active: _catFilter == e.key, onTap: () => setState(() => _catFilter = e.key), label: categoryLabel(context, e.key), dot: e.value.color),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (tasks.isEmpty)
            EmptyState(
              title: l10n.tasksEmptyTitle,
              subtitle: l10n.tasksEmptySubtitle,
              actionLabel: l10n.createTaskButton,
              onAction: () => _openCreate(context, store, todayKey, settings),
              icon: Icons.checklist,
            )
          else if (filtered.isEmpty)
            EmptyState(title: l10n.tasksNoMatchTitle, subtitle: l10n.tasksNoMatchSubtitle, icon: Icons.filter_alt_outlined)
          else
            ...filtered.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskRow(
                    task: t,
                    settings: settings,
                    todayKey: todayKey,
                    onEdit: () => _openEdit(context, store, t, settings),
                    onToggle: () => store.toggleTaskComplete(t.id),
                    onDelete: () => showMrdConfirm(
                      context,
                      title: l10n.taskDeleteTitle,
                      description: l10n.taskDeleteDesc(t.title),
                      confirmLabel: l10n.deleteLabel,
                      onConfirm: () => store.deleteTask(t.id),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context, MeridianStore store, String todayKey, UserSettings settings) {
    showTaskModal(
      context,
      mode: 'create',
      presetDate: todayKey,
      timeFormat24: settings.timeFormat24,
      onSave: store.addTask,
    );
  }

  void _openEdit(BuildContext context, MeridianStore store, Task task, UserSettings settings) {
    showTaskModal(
      context,
      mode: 'edit',
      task: task,
      presetDate: task.taskDate,
      timeFormat24: settings.timeFormat24,
      onSave: (data) => store.updateTask(task.id, (current) => current.copyWith(
            title: data.title,
            category: data.category,
            priority: data.priority,
            status: data.status,
            start: data.start,
            duration: data.duration,
            notes: data.notes,
            taskDate: data.taskDate,
            link: data.link,
          )),
      onDelete: () {
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        showMrdConfirm(
          context,
          title: l10n.taskDeleteTitle,
          description: l10n.taskDeleteDesc(task.title),
          confirmLabel: l10n.deleteLabel,
          onConfirm: () => store.deleteTask(task.id),
        );
      },
    );
  }
}

String? _dateBadgeLabel(String taskDate, String todayKey, AppLocalizations l10n) {
  if (taskDate == todayKey) return null;
  final d = parseDayKey(taskDate);
  return fmtDateShort(d, l10n);
}

/// BUG FIX (audit report #2): the task list's "open link" button used to
/// be a bare `launchUrl(Uri.parse(task.link!), ...)` — no validation, no
/// error handling, no user feedback on failure. `Uri.parse` (not
/// `tryParse`) throws outright on a malformed string, and a plain
/// domain with no scheme (exactly what the New Task modal's own Link
/// field hint suggests typing — "e.g. coursera.org/learn/your-course")
/// produces a URI `launchUrl` can't actually open. Tasks created through
/// the modal's own `_submit()` already normalize/validate the link at
/// save time, so this mainly matters for data that entered some other
/// way (an older backup, a future import path) — but there's no reason
/// the tap handler itself shouldn't be defensive too, and
/// `resource_card_widget.dart`'s `_open()` already established exactly
/// this pattern for the same feature elsewhere in the app. Mirrored here
/// instead of inventing a different approach for what's the same
/// problem: normalize (add `https://` if missing), validate, launch
/// inside a try/catch, and surface a toast on any failure instead of
/// doing nothing visible.
Future<void> _openTaskLink(
    BuildContext context, String rawLink, AppLocalizations l10n) async {
  final store = context.read<MeridianStore>();
  final raw = rawLink.trim();
  if (raw.isEmpty) {
    store.notify(ToastKind.error, l10n.resourceInvalidLinkError);
    return;
  }
  final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
  if (uri == null || !uri.hasAuthority) {
    store.notify(ToastKind.error, l10n.resourceInvalidLinkError);
    return;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) store.notify(ToastKind.error, l10n.resourceOpenLinkError);
  } catch (_) {
    store.notify(ToastKind.error, l10n.resourceOpenLinkError);
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final UserSettings settings;
  final String todayKey;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskRow({
    required this.task,
    required this.settings,
    required this.todayKey,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final cat = kCategories[task.category]!;
    final pri = kPriorities[task.priority]!;
    final completed = task.status == TaskStatus.completed;
    final skipped = task.status == TaskStatus.skipped;
    final inProgress = task.status == TaskStatus.inProgress;
    final dateBadge = _dateBadgeLabel(task.taskDate, todayKey, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12), color: c.surface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MrdCheckbox(checked: completed, onTap: onToggle, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      fontStyle: skipped ? FontStyle.italic : FontStyle.normal,
                      color: completed || skipped ? c.textFaint : c.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${dateBadge != null ? '$dateBadge · ' : ''}${minutesToLabel(task.start, l10n, settings.timeFormat24)} · ${task.duration}m',
                        style: TextStyle(fontSize: 11, color: dateBadge != null ? c.primary : c.textFaint, fontFamily: 'monospace'),
                      ),
                      _badge(categoryLabel(context, task.category), cat.color),
                      _badge(priorityLabel(context, task.priority), pri.color),
                      if (inProgress)
                        _badge(l10n.statusInProgress, c.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (task.link != null && task.link!.trim().isNotEmpty) ...[
            MrdIconOnlyButton(onTap: () => _openTaskLink(context, task.link!, l10n), icon: Icons.open_in_new, label: l10n.openLinkLabel, size: 14),
            const SizedBox(width: 8), // UI FIX (audit report #8): see MrdIconOnlyButton's own comment — keeps expanded tap targets from overlapping.
          ],
          MrdIconOnlyButton(onTap: onEdit, icon: Icons.edit_outlined, label: l10n.editLabel, size: 14),
          const SizedBox(width: 8),
          MrdIconOnlyButton(onTap: onDelete, icon: Icons.delete_outline, label: l10n.deleteLabel, size: 14, danger: true),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
