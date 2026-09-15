import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../store/meridian_store.dart';
import '../shared/field_label.dart';
import '../shared/mrd_bidi_text_field.dart';
import '../shared/modal_focus.dart';

/// Ported from the inline habit create/edit modal in HabitsScreen.tsx.
Future<void> showHabitModal(
  BuildContext context, {
  Habit? habit,
  required void Function(NewHabit data) onSave,
  VoidCallback? onDelete,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        HabitModalSheet(habit: habit, onSave: onSave, onDelete: onDelete),
  );
}

class HabitModalSheet extends StatefulWidget {
  final Habit? habit;
  final void Function(NewHabit data) onSave;
  final VoidCallback? onDelete;

  const HabitModalSheet(
      {super.key, this.habit, required this.onSave, this.onDelete});

  @override
  State<HabitModalSheet> createState() => _HabitModalSheetState();
}

class _HabitModalSheetState extends State<HabitModalSheet> {
  late final TextEditingController _nameCtrl;
  // BUG FIX: see requestFocusOnRouteSettled() call in
  // didChangeDependencies below — same fix as task_modal.dart's title
  // field.
  final FocusNode _nameFocus = FocusNode();
  bool _focusRouteListenerAttached = false;
  late String _emoji;
  late Color _color;
  // NOTIFICATIONS SYSTEM: null = no reminder for this habit.
  TimeOfDay? _reminderTime;
  String? _error;
  bool _confirmingDelete = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.habit?.name ?? '');
    _emoji = widget.habit?.emoji ?? kHabitEmojis.first;
    _color = widget.habit != null
        ? hexToColor(widget.habit!.color)
        : kHabitColors.first;
    final existingReminder = widget.habit?.reminderTime;
    if (existingReminder != null) {
      final parts = existingReminder.split(':');
      final h = int.tryParse(parts[0]);
      final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (h != null && m != null) _reminderTime = TimeOfDay(hour: h, minute: m);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_focusRouteListenerAttached) {
      _focusRouteListenerAttached = true;
      requestFocusOnRouteSettled(context, _nameFocus, mounted: () => mounted);
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.habitGiveNameError);
      return;
    }
    widget.onSave(NewHabit(
      name: _nameCtrl.text.trim(),
      emoji: _emoji,
      color: colorToHex(_color),
      reminderTime: _reminderTime == null
          ? null
          : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
      // Only actually used by the create path (store.addHabit) — editing
      // an existing habit goes through habit.copyWith(...) instead, which
      // never touches createdDate, so this value is harmless filler on
      // that path.
      createdDate: dayKey(DateTime.now()),
    ));
    Navigator.of(context).pop();
  }

  bool _habitRemindersEnabled(BuildContext context) =>
      context.watch<MeridianStore>().settings.habitRemindersEnabled;

  Future<void> _pickReminderTime() async {    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.habit != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
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
                  Text(isEdit ? l10n.editHabitModalTitle : l10n.newHabitModalTitle,
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
              FieldLabel(l10n.nameLabel, c: c),
              MrdBidiTextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: mrdInputDecoration(c, hint: l10n.habitNameHint),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: TextStyle(color: c.danger, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              FieldLabel(l10n.iconLabel, c: c),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kHabitEmojis.map((e) {
                  final selected = e == _emoji;
                  return InkWell(
                    onTap: () => setState(() => _emoji = e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selected ? c.primaryBg : c.surface,
                        border: Border.all(
                            color: selected ? c.primary : c.border),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 19)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FieldLabel(l10n.colorLabel, c: c),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kHabitColors.map((col) {
                  final selected = col == _color;
                  return InkWell(
                    onTap: () => setState(() => _color = col),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: col,
                        border: selected
                            ? Border.all(color: c.text, width: 2.5)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FieldLabel(l10n.reminderLabel, c: c),
              InkWell(
                onTap: _pickReminderTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                    color: c.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_outlined, size: 16, color: c.textDim),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _reminderTime == null
                              ? l10n.noReminderLabel
                              : _reminderTime!.format(context),
                          style: TextStyle(
                              fontSize: 13.5,
                              color: _reminderTime == null ? c.textFaint : c.text),
                        ),
                      ),
                      if (_reminderTime != null)
                        InkWell(
                          onTap: () => setState(() => _reminderTime = null),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 16, color: c.textFaint),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_reminderTime != null && !_habitRemindersEnabled(context))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 13, color: c.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(l10n.habitRemindersOffWarning,
                              style:
                                  TextStyle(fontSize: 11.5, color: c.warning)),
                        ),
                        TextButton(
                          onPressed: () => context.read<MeridianStore>().updateSettings(
                              (s) => s.copyWith(habitRemindersEnabled: true)),
                          style: TextButton.styleFrom(
                              foregroundColor: c.warning,
                              minimumSize: const Size(0, 24),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: VisualDensity.compact),
                          child: Text(l10n.turnOnLabel,
                              style: const TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (widget.onDelete != null)
                    _confirmingDelete
                        ? Expanded(
                            child: Row(children: [
                              Expanded(
                                  child: Text(l10n.habitDeleteTitle,
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
                      child: Text(isEdit ? l10n.saveChangesButton : l10n.addHabitButton),
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
