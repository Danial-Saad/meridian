import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/mrd_checkbox.dart';
import '../widgets/tasks/task_modal.dart';

const int _plannerStartHour = 0;
const int _plannerEndHour = 24;
const double _hourHeight = 68.0;
const int _snapMinutes = 15;
const int _minDuration = 15;

double _yFromMinutes(int mins) =>
    ((mins - _plannerStartHour * 60) / 60) * _hourHeight;

class _PositionedTask {
  final Task task;
  final int col;
  final int colCount;
  const _PositionedTask(
      {required this.task, required this.col, required this.colCount});
}

/// Ported field-for-field from layoutColumns() in PlannerScreen.tsx —
/// assigns overlapping tasks to side-by-side columns instead of stacking.
List<_PositionedTask> _layoutColumns(List<Task> tasks) {
  final sorted = [...tasks]..sort((a, b) => a.start.compareTo(b.start));
  final clusters = <List<Task>>[];
  var current = <Task>[];
  var clusterEnd = -1 << 30;
  for (final t in sorted) {
    if (t.start >= clusterEnd) {
      if (current.isNotEmpty) clusters.add(current);
      current = [t];
      clusterEnd = t.start + t.duration;
    } else {
      current.add(t);
      clusterEnd =
          clusterEnd > t.start + t.duration ? clusterEnd : t.start + t.duration;
    }
  }
  if (current.isNotEmpty) clusters.add(current);

  final result = <_PositionedTask>[];
  for (final cluster in clusters) {
    final columnEnds = <int>[];
    final colOf = <String, int>{};
    for (final t in cluster) {
      var colIndex = columnEnds.indexWhere((end) => end <= t.start);
      if (colIndex == -1) {
        columnEnds.add(t.start + t.duration);
        colIndex = columnEnds.length - 1;
      } else {
        columnEnds[colIndex] = t.start + t.duration;
      }
      colOf[t.id] = colIndex;
    }
    final colCount = columnEnds.length;
    for (final t in cluster) {
      result
          .add(_PositionedTask(task: t, col: colOf[t.id]!, colCount: colCount));
    }
  }
  return result;
}

enum _DragMode { move, resize }

class _DragState {
  final String id;
  final _DragMode mode;
  final Offset startGlobal;
  final int originStart;
  final int originDuration;
  int previewStart;
  int previewDuration;

  _DragState({
    required this.id,
    required this.mode,
    required this.startGlobal,
    required this.originStart,
    required this.originDuration,
  })  : previewStart = originStart,
        previewDuration = originDuration;
}

/// Ported from PlannerScreen.tsx. The desktop version drags with a mouse
/// pointer directly on the block; on a touch screen that gesture collides
/// with the surrounding scroll view, so blocks use long-press-then-drag —
/// the same pattern Flutter's own ReorderableListView uses to pick an item
/// up inside a scrollable list without fighting the scroll gesture.
class PlannerScreen extends StatefulWidget {
  final void Function(int startMin, String date) onSlotClick;

  const PlannerScreen({super.key, required this.onSlotClick});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late String _selectedDate;
  final _scrollController = ScrollController();
  bool _hasAutoScrolled = false;
  bool _showJumpToNow = false;
  _DragState? _drag;

  @override
  void initState() {
    super.initState();
    _selectedDate = dayKey(DateTime.now());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Only meaningful on today's view (that's the only day with a "now"
  // line at all). Shows a small floating button once you've scrolled far
  // enough from the current-time line that it's no longer obviously one
  // swipe away — mirrors the same offset math the one-time auto-scroll
  // on open already uses, so tapping it lands in the same spot opening
  // the screen fresh would have.
  void _onScroll() {
    if (_selectedDate != dayKey(DateTime.now())) {
      if (_showJumpToNow) setState(() => _showJumpToNow = false);
      return;
    }
    final nowOffset = _yFromMinutes(
        DateTime.now().hour * 60 + DateTime.now().minute);
    final farFromNow = (_scrollController.offset - (nowOffset - 160)).abs() > 200;
    if (farFromNow != _showJumpToNow) {
      setState(() => _showJumpToNow = farFromNow);
    }
  }

  void _scrollToNow() {
    final nowOffset = _yFromMinutes(
        DateTime.now().hour * 60 + DateTime.now().minute);
    _scrollController.animateTo(
      clampDouble(nowOffset - 160, 0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _goToDate(int deltaDays) {
    final d = parseDayKey(_selectedDate).add(Duration(days: deltaDays));
    setState(() => _selectedDate = dayKey(d));
  }

  Future<void> _pickDate() async {
    final initial = parseDayKey(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 3),
      lastDate: DateTime(initial.year + 3),
    );
    if (picked != null) setState(() => _selectedDate = dayKey(picked));
  }

  bool _findCollision(
      List<Task> tasksForDate, String id, int start, int duration) {
    return tasksForDate.any((t) =>
        t.id != id &&
        t.status != TaskStatus.skipped &&
        t.start < start + duration &&
        t.start + t.duration > start);
  }

  int _snap(double v) => (v / _snapMinutes).round() * _snapMinutes;
  int _clampInt(int v, int min, int max) => v < min ? min : (v > max ? max : v);

  void _startDrag(Task task, _DragMode mode, Offset globalPos) {
    HapticFeedback.mediumImpact();
    setState(() {
      _drag = _DragState(
          id: task.id,
          mode: mode,
          startGlobal: globalPos,
          originStart: task.start,
          originDuration: task.duration);
    });
  }

  void _updateDrag(Offset globalPos) {
    final drag = _drag;
    if (drag == null) return;
    final deltaY = globalPos.dy - drag.startGlobal.dy;
    final deltaMinutes = _snap((deltaY / _hourHeight) * 60);
    setState(() {
      if (drag.mode == _DragMode.move) {
        drag.previewStart = _clampInt(drag.originStart + deltaMinutes,
            _plannerStartHour * 60, _plannerEndHour * 60 - drag.originDuration);
        drag.previewDuration = drag.originDuration;
      } else {
        drag.previewDuration = _clampInt(drag.originDuration + deltaMinutes,
            _minDuration, _plannerEndHour * 60 - drag.originStart);
        drag.previewStart = drag.originStart;
      }
    });
  }

  void _endDrag(MeridianStore store) {
    final drag = _drag;
    if (drag == null) return;
    // Collisions are no longer rejected here — the grid already renders
    // overlapping tasks side by side in their own columns (see
    // _layoutColumns), and manually typing an overlapping time in the
    // edit modal has always been allowed. Blocking only the drag-and-drop
    // path was an inconsistency, not a real guardrail: the red tint on
    // the dragged block during the gesture (see _buildTimeBlock) still
    // gives a heads-up that a drop will land on another task.
    if (drag.mode == _DragMode.move) {
      store.updateTask(drag.id, (t) => t.copyWith(start: drag.previewStart));
    } else {
      store.updateTask(
          drag.id, (t) => t.copyWith(duration: drag.previewDuration));
    }
    setState(() => _drag = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final settings = store.settings;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final todayKey = dayKey(now);
    final isToday = _selectedDate == todayKey;

    final tasksForDate =
        store.tasks.where((t) => t.taskDate == _selectedDate).toList();
    final visibleTasks = tasksForDate
        .where((t) =>
            t.start >= _plannerStartHour * 60 && t.start < _plannerEndHour * 60)
        .toList();
    final positioned = _layoutColumns(visibleTasks);

    final nowMinutes = now.hour * 60 + now.minute;
    final nowOffset = _yFromMinutes(nowMinutes);
    final showNowLine = isToday &&
        nowMinutes >= _plannerStartHour * 60 &&
        nowMinutes <= _plannerEndHour * 60;

    if (showNowLine && !_hasAutoScrolled) {
      _hasAutoScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(clampDouble(
              nowOffset - 160, 0, _scrollController.position.maxScrollExtent));
        }
      });
    }

    final selectedDt = parseDayKey(_selectedDate);
    final dateLabel = isToday
        ? l10n.todayWord
        : DateFormat('EEEE, MMMM d', Localizations.localeOf(context).languageCode)
            .format(selectedDt);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.plannerTitle,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 4),
            Text(l10n.plannerHint,
                style: TextStyle(fontSize: 12.5, color: c.textDim)),
            const SizedBox(height: 12),
            Row(children: [
              _navBtn(c, Icons.chevron_left, () => _goToDate(-1),
                  tooltip: l10n.previousDayTooltip),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: c.border),
                      color: isToday ? c.primaryBg : c.surface,
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month,
                              size: 14, color: isToday ? c.primary : c.text),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(dateLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isToday ? c.primary : c.text)),
                          ),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _navBtn(c, Icons.chevron_right, () => _goToDate(1),
                  tooltip: l10n.nextDayTooltip),
              if (!isToday) ...[
                const SizedBox(width: 6),
                _navBtn(c, Icons.today,
                    () => setState(() => _selectedDate = todayKey),
                    tooltip: l10n.jumpToTodayTooltip),
              ],
            ]),
            const SizedBox(height: 14),
            if (visibleTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: EmptyState(
                    title: l10n.dashboardClearTitle,
                    subtitle: l10n.plannerEmptySubtitle),
              ),
            Expanded(
              child: Stack(children: [
                GestureDetector(
                // Same forward/back semantics as the chevron buttons right
                // next to this grid: a left swipe reveals the next day
                // (same direction as tapping chevron_right), a right swipe
                // goes back — independent of text directionality, since
                // this is a physical swipe gesture on a timeline, not text.
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  _goToDate(v < 0 ? 1 : -1);
                },
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(16),
                      color: c.surface),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    const totalHeight =
                        (_plannerEndHour - _plannerStartHour) * _hourHeight;
                    final usableWidth = constraints.maxWidth - 88;
                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: _drag == null
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: totalHeight,
                        width: constraints.maxWidth,
                        child: Stack(children: [
                          for (var h = _plannerStartHour;
                              h < _plannerEndHour;
                              h++)
                            Positioned(
                              top: (h - _plannerStartHour) * _hourHeight,
                              left: 0,
                              right: 0,
                              height: _hourHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(color: c.border))),
                                child: Row(children: [
                                  SizedBox(
                                    width: 60,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, right: 8),
                                      child: Text(
                                        settings.timeFormat24
                                            ? pad2(h)
                                            : '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'AM' : 'PM'}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: c.textFaint,
                                            fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => widget.onSlotClick(
                                          h * 60, _selectedDate),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          if (showNowLine)
                            Positioned(
                              top: nowOffset,
                              left: 60,
                              right: 12,
                              child: IgnorePointer(
                                child: Row(children: [
                                  Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                          color: c.danger,
                                          shape: BoxShape.circle)),
                                  Expanded(
                                      child: Container(
                                          height: 1.5,
                                          color:
                                              c.danger.withValues(alpha: 0.7))),
                                ]),
                              ),
                            ),
                          for (final p in positioned)
                            _buildTimeBlock(context, c, store, p, tasksForDate,
                                usableWidth, settings),
                        ]),
                      ),
                    );
                  }),
                ),
              ),
              ),
              if (isToday && _showJumpToNow)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Material(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 3,
                    child: InkWell(
                      onTap: _scrollToNow,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 15, color: c.primaryInk),
                              const SizedBox(width: 6),
                              Text(l10n.jumpToNowTooltip,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: c.primaryInk)),
                            ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(MeridianColors c, IconData icon, VoidCallback onTap,
      {required String tooltip}) {
    // A11Y FIX: was a bare icon+InkWell with no label at all — a screen
    // reader had nothing to announce for "previous day" / "next day" /
    // "jump to today". Tooltip both fixes that (Tooltip auto-provides the
    // Semantics label) and adds a normal long-press hint for sighted users.
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.border),
              color: c.surface),
          child: Icon(icon, size: 18, color: c.textDim),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(
    BuildContext context,
    MeridianColors c,
    MeridianStore store,
    _PositionedTask p,
    List<Task> tasksForDate,
    double usableWidth,
    UserSettings settings,
  ) {
    final isDragging = _drag?.id == p.task.id;
    final start = isDragging ? _drag!.previewStart : p.task.start;
    final duration = isDragging ? _drag!.previewDuration : p.task.duration;
    final top = _yFromMinutes(start);
    final height =
        clampDouble((duration / 60) * _hourHeight, 26.0, double.infinity);
    final collides =
        isDragging && _findCollision(tasksForDate, p.task.id, start, duration);

    final widthPct = 100 / p.colCount;
    final leftPct = p.col * widthPct;
    final left = 76 + (leftPct / 100) * usableWidth;
    final width = (widthPct / 100) * usableWidth - 4;

    final cat = kCategories[p.task.category]!;
    final pri = kPriorities[p.task.priority]!;
    final completed = p.task.status == TaskStatus.completed;
    final inProgress = p.task.status == TaskStatus.inProgress;
    // BUG FIX (reported: a real overflow banner — "BOTTOM OVERFLOWED BY
    // 4.0 PIXELS" — rendered directly inside a task block on the Planner
    // grid). The non-compact layout below shows two rows (the icon/title
    // row, plus a start–end time subtitle) inside vertical padding of 7px
    // top + 7px bottom. Working out roughly what that actually needs to
    // fit — ~18-20px for row 1, ~13-14px for row 2, 1px of spacing
    // between them, plus the 14px of padding — lands right around 46-49px
    // *before accounting for real font-metric rounding*, which is exactly
    // where the old `height < 46` cutoff drew the line: it let blocks in
    // with essentially zero margin for error. `_hourHeight` is 68px/hr,
    // so `height` crosses 46px around a 40-minute task — a completely
    // ordinary duration (this bug's repro was a task named "Break").
    // Raised to 56 (~49-minute task) for real breathing room: anything
    // under that now safely takes the single-row "compact" layout (which
    // has no overflow risk — it has no second row at all, and centers its
    // one row vertically), at the cost of not showing the time-range
    // subtitle on some medium-length tasks that could technically have
    // fit it.
    final compact = height < 56;
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      top: top,
      left: left,
      width: width < 40 ? 40 : width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDragging
            ? null
            : () => _openEdit(context, store, p.task, settings),
        onLongPressStart: (d) =>
            _startDrag(p.task, _DragMode.move, d.globalPosition),
        onLongPressMoveUpdate: (d) => _updateDrag(d.globalPosition),
        onLongPressEnd: (_) => _endDrag(store),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10, vertical: compact ? 4 : 7),
          decoration: BoxDecoration(
            color: collides
                ? c.danger.withValues(alpha: 0.14)
                : completed
                    ? c.textFaint.withValues(alpha: 0.06)
                    : cat.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: collides
                    ? c.danger
                    : completed
                        ? c.border
                        : cat.color.withValues(alpha: 0.33)),
            boxShadow: isDragging
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12)
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                  left: -10,
                  top: -7,
                  bottom: -7,
                  width: 3,
                  child: Container(color: collides ? c.danger : cat.color)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Row(children: [
                    MrdCheckbox(
                        checked: completed,
                        onTap: () => store.toggleTaskComplete(p.task.id),
                        size: 15,
                        // Planner packs blocks tightly (only a 7px gap
                        // before the next element, sometimes stacked right
                        // above/below another block), so the default 32px
                        // tap halo would risk overlapping a neighbor's own
                        // touch target. 22px is still a real improvement
                        // (~2x the tappable area of the 15px original)
                        // without eating into surrounding blocks.
                        tapTargetSize: 22),
                    const SizedBox(width: 5),
                    // Shape cue alongside the color, not a replacement for
                    // it — see the comment on CategoryInfo.icon.
                    Tooltip(
                      message: categoryLabel(context, p.task.category),
                      child: Icon(cat.icon,
                          size: compact ? 10 : 12,
                          color: completed ? c.textFaint : cat.color),
                    ),
                    if (!compact && inProgress) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: l10n.statusInProgress,
                        child: Icon(Icons.play_circle_outline,
                            size: 12, color: c.primary),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          color: completed ? c.textFaint : c.text,
                        ),
                      ),
                    ),
                    if (!compact && p.task.priority == TaskPriority.urgent)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: pri.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(l10n.urgentBadge,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: pri.color)),
                      ),
                    if (!compact && p.task.link != null)
                      Tooltip(
                        message: l10n.openLinkLabel,
                        child: InkWell(
                          onTap: () => launchUrl(Uri.parse(p.task.link!),
                              mode: LaunchMode.externalApplication),
                          child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.open_in_new,
                                  size: 13, color: c.textFaint)),
                        ),
                      ),
                    Tooltip(
                      message: l10n.deleteLabel,
                      child: InkWell(
                        onTap: () => showMrdConfirm(
                          context,
                          title: l10n.timeBlockDeleteTitle,
                          description: l10n.timeBlockDeleteDesc(p.task.title),
                          confirmLabel: l10n.deleteLabel,
                          onConfirm: () => store.deleteTask(p.task.id),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline,
                              size: compact ? 12 : 13, color: c.textFaint)),
                      ),
                    ),
                  ]),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(left: 22, top: 1),
                      child: Text(
                        '${minutesToLabel(p.task.start, l10n, settings.timeFormat24)} – ${minutesToLabel(p.task.start + p.task.duration, l10n, settings.timeFormat24)}',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: c.textFaint,
                            fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
              // Resize handle.
              Positioned(
                left: 0,
                right: 0,
                bottom: -6,
                height: 18,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPressStart: (d) =>
                      _startDrag(p.task, _DragMode.resize, d.globalPosition),
                  onLongPressMoveUpdate: (d) => _updateDrag(d.globalPosition),
                  onLongPressEnd: (_) => _endDrag(store),
                  child: Center(
                    child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                            color: cat.color
                                .withValues(alpha: isDragging ? 0.9 : 0.45),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, MeridianStore store, Task task,
      UserSettings settings) {
    showTaskModal(
      context,
      mode: 'edit',
      task: task,
      presetDate: task.taskDate,
      timeFormat24: settings.timeFormat24,
      onSave: (data) => store.updateTask(
          task.id,
          (current) => current.copyWith(
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
          title: l10n.timeBlockDeleteTitle,
          description: l10n.timeBlockDeleteDesc(task.title),
          confirmLabel: l10n.deleteLabel,
          onConfirm: () => store.deleteTask(task.id),
        );
      },
    );
  }
}
