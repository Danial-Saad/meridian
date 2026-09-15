import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../shared/field_label.dart';
import '../shared/mrd_bidi_text_field.dart';
import '../shared/modal_focus.dart';

class TaskModalResult {
  final NewTask data;
  const TaskModalResult(this.data);
}

Future<void> showTaskModal(
  BuildContext context, {
  required String mode, // 'create' | 'edit'
  Task? task,
  int? presetStart,
  required String presetDate,
  required bool timeFormat24,
  required void Function(NewTask data) onSave,
  VoidCallback? onDelete,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TaskModalSheet(
      mode: mode,
      task: task,
      presetStart: presetStart,
      presetDate: presetDate,
      timeFormat24: timeFormat24,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class TaskModalSheet extends StatefulWidget {
  final String mode;
  final Task? task;
  final int? presetStart;
  final String presetDate;
  final bool timeFormat24;
  final void Function(NewTask data) onSave;
  final VoidCallback? onDelete;

  const TaskModalSheet({
    super.key,
    required this.mode,
    this.task,
    this.presetStart,
    required this.presetDate,
    required this.timeFormat24,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<TaskModalSheet> createState() => _TaskModalSheetState();
}

class _TaskModalSheetState extends State<TaskModalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _durationCtrl;
  // BUG FIX: see requestFocusOnRouteSettled() call in
  // didChangeDependencies below for why this replaces a plain
  // `autofocus: true` on the title field.
  final FocusNode _titleFocus = FocusNode();
  bool _focusRouteListenerAttached = false;
  late TaskCategory _category;
  late TaskPriority _priority;
  late TaskStatus _status;
  late String _taskDate;
  late int _startH;
  late int _startM;
  String? _error;
  bool _confirmingDelete = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _linkCtrl = TextEditingController(text: t?.link ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _category = t?.category ?? TaskCategory.study;
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.todo;
    _taskDate = t?.taskDate ?? widget.presetDate;
    final startMin = t?.start ?? widget.presetStart ?? 9 * 60;
    _startH = startMin ~/ 60;
    _startM = startMin % 60;
    _durationCtrl = TextEditingController(text: (t?.duration ?? 60).toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_focusRouteListenerAttached) {
      _focusRouteListenerAttached = true;
      requestFocusOnRouteSettled(context, _titleFocus, mounted: () => mounted);
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _notesCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  String? _normalizeLink(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.taskGiveTitleError);
      return;
    }
    final normalizedLink = _normalizeLink(_linkCtrl.text);
    if (normalizedLink != null) {
      final uri = Uri.tryParse(normalizedLink);
      if (uri == null || !uri.hasAuthority) {
        setState(() => _error = l10n.taskInvalidLinkError);
        return;
      }
    }
    final duration = int.tryParse(_durationCtrl.text.trim());
    if (duration == null || duration < 1 || duration > 24 * 60) {
      setState(() => _error = l10n.taskInvalidDurationError);
      return;
    }
    widget.onSave(NewTask(
      title: _titleCtrl.text.trim(),
      category: _category,
      priority: _priority,
      status: _status,
      start: _startH * 60 + _startM,
      duration: duration,
      notes: _notesCtrl.text,
      taskDate: _taskDate,
      link: normalizedLink,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final initial = parseDayKey(_taskDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 3),
      lastDate: DateTime(initial.year + 3),
    );
    if (picked != null) setState(() => _taskDate = dayKey(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.mode == 'edit';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? l10n.editTaskModalTitle : l10n.newTaskModalTitle,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: c.textDim)),
                ],
              ),
              const SizedBox(height: 8),
              FieldLabel(l10n.titleLabel, c: c),
              MrdBidiTextField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: mrdInputDecoration(c,
                    hint: l10n.taskTitleHint),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.error_outline, size: 13, color: c.danger),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(color: c.danger, fontSize: 12))),
                ]),
              ],
              const SizedBox(height: 14),
              FieldLabel(l10n.dateLabel, c: c),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: mrdInputDecoration(c),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_taskDate,
                          style: TextStyle(color: c.text, fontSize: 13.5)),
                      Icon(Icons.calendar_today, size: 15, color: c.textFaint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.categoryLabelField, c: c),
                        _Dropdown<TaskCategory>(
                          c: c,
                          value: _category,
                          items: kCategories.entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(e.value.icon, size: 14, color: e.value.color),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(categoryLabel(context, e.key),
                                            overflow: TextOverflow.ellipsis)),
                                  ])))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.priorityLabelField, c: c),
                        _Dropdown<TaskPriority>(
                          c: c,
                          value: _priority,
                          items: kPriorities.entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key, child: Text(priorityLabel(context, e.key))))
                              .toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ]),
                ),
              ]),
              if (isEdit) ...[
                const SizedBox(height: 14),
                FieldLabel(l10n.statusLabelField, c: c),
                _Dropdown<TaskStatus>(
                  c: c,
                  value: _status,
                  items: kTaskStatuses
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(taskStatusLabel(context, s.id))))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.startHourLabel, c: c),
                        _Dropdown<int>(
                          c: c,
                          value: _startH,
                          items: List.generate(
                              24,
                              (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(hourToLabel(
                                      h, l10n, widget.timeFormat24)))),
                          onChanged: (v) => setState(() => _startH = v!),
                        ),
                      ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.minuteLabel, c: c),
                        _Dropdown<int>(
                          c: c,
                          value: _startM,
                          items: [0, 15, 30, 45]
                              .map((m) => DropdownMenuItem(
                                  value: m, child: Text(':${pad2(m)}')))
                              .toList(),
                          onChanged: (v) => setState(() => _startM = v!),
                        ),
                      ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.durationMinLabel, c: c),
                        // Numeric-only: intentionally left as a plain
                        // TextField (no bidi handling needed or wanted).
                        TextField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: c.text, fontSize: 13.5),
                          decoration: mrdInputDecoration(c),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ]),
                ),
              ]),
              const SizedBox(height: 14),
              FieldLabel(l10n.linkLabel, c: c),
              // URLs must stay LTR regardless of surrounding content —
              // deliberately a plain TextField with an explicit direction
              // here, not MrdBidiTextField.
              TextField(
                controller: _linkCtrl,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: c.text, fontSize: 13.5),
                decoration: mrdInputDecoration(c,
                    hint: l10n.taskLinkHint),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              FieldLabel(l10n.notesLabel, c: c),
              MrdBidiTextField(
                controller: _notesCtrl,
                maxLines: 2,
                style: TextStyle(color: c.text, fontSize: 13.5),
                decoration: mrdInputDecoration(c, hint: l10n.optionalLabel),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.onDelete != null)
                    _confirmingDelete
                        ? Expanded(
                            child: Row(children: [
                              Expanded(
                                  child: Text(l10n.taskDeleteTitle,
                                      style: TextStyle(
                                          fontSize: 12, color: c.textDim))),
                              TextButton(
                                onPressed: widget.onDelete,
                                style: TextButton.styleFrom(
                                    foregroundColor: c.danger),
                                child: Text(l10n.yesDeleteLabel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _confirmingDelete = false),
                                style: TextButton.styleFrom(
                                    foregroundColor: c.textFaint),
                                child: Text(l10n.cancelLabel),
                              ),
                            ]),
                          )
                        : TextButton.icon(
                            onPressed: () =>
                                setState(() => _confirmingDelete = true),
                            style:
                                TextButton.styleFrom(foregroundColor: c.danger),
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: Text(l10n.deleteLabel),
                          ),
                  if (!_confirmingDelete) ...[
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: c.textDim,
                          side: BorderSide(color: c.border)),
                      child: Text(l10n.cancelLabel),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.primaryInk),
                      child: Text(isEdit ? l10n.saveChangesButton : l10n.addToDayButton),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final MeridianColors c;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown(
      {required this.c,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          style: TextStyle(color: c.text, fontSize: 13.5),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
