import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../store/plan_my_day.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../shared/field_label.dart';
import '../shared/mrd_bidi_text_field.dart';

/// Ported from PlanMyDayModal.tsx — a 3-step wizard: priorities, commitments
/// + focus hours, then a review of the generated schedule before applying.
Future<void> showPlanMyDayModal(
  BuildContext context, {
  required String targetDate,
  required List<Task> existingTasksForDate,
  required void Function(List<NewTask> blocks) onApply,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PlanMyDayModalSheet(
      targetDate: targetDate,
      existingTasksForDate: existingTasksForDate,
      onApply: onApply,
    ),
  );
}

class PlanMyDayModalSheet extends StatefulWidget {
  final String targetDate;
  final List<Task> existingTasksForDate;
  final void Function(List<NewTask> blocks) onApply;

  const PlanMyDayModalSheet({
    super.key,
    required this.targetDate,
    required this.existingTasksForDate,
    required this.onApply,
  });

  @override
  State<PlanMyDayModalSheet> createState() => _PlanMyDayModalSheetState();
}

class _PlanMyDayModalSheetState extends State<PlanMyDayModalSheet> {
  int _step = 0;
  final List<TextEditingController> _priorityCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  // Parallel to _priorityCtrls (same index = same priority row). Defaults
  // to Work as a reasonably neutral guess — easy to change per-priority
  // with the icon picker next to each field.
  final List<TaskCategory> _priorityCategories = [
    TaskCategory.work,
    TaskCategory.work,
    TaskCategory.work,
  ];
  final _commitmentsCtrl = TextEditingController();
  double _focusHours = 4;
  List<NewTask>? _generated;

  @override
  void dispose() {
    for (final c in _priorityCtrls) {
      c.dispose();
    }
    _commitmentsCtrl.dispose();
    super.dispose();
  }

  // Wizard originally hard-capped at exactly 3 priority fields — anyone
  // with a 4th or 5th thing to plan simply had nowhere to put it. Kept a
  // ceiling rather than letting the list grow unbounded: past ~6
  // priorities the per-task time math (see _minimumTimeWarningText)
  // starts fighting itself, and the step becomes a scroll-heavy form
  // rather than a quick wizard.
  static const _maxPriorities = 6;

  void _addPriority() {
    setState(() {
      _priorityCtrls.add(TextEditingController());
      _priorityCategories.add(TaskCategory.work);
    });
  }

  void _removePriority(int i) {
    setState(() {
      _priorityCtrls.removeAt(i).dispose();
      _priorityCategories.removeAt(i);
    });
  }

  void _goToReview() {
    final l10n = AppLocalizations.of(context)!;
    final nonEmptyIndices = [
      for (var i = 0; i < _priorityCtrls.length; i++)
        if (_priorityCtrls[i].text.trim().isNotEmpty) i
    ];
    final priorities =
        nonEmptyIndices.map((i) => _priorityCtrls[i].text.trim()).toList();
    final categories =
        nonEmptyIndices.map((i) => _priorityCategories[i]).toList();
    final now = DateTime.now();
    final blocks = generateScheduleFromInputs(
      priorities,
      _focusHours,
      widget.existingTasksForDate,
      _commitmentsCtrl.text,
      widget.targetDate,
      focusBlockFallback: l10n.focusBlockFallback,
      breakLabel: l10n.breakTaskTitle,
      continuedSuffix: l10n.continuedSuffix,
      generatedByNote: l10n.generatedByPlanMyDayNote,
      // Only meaningful for today — a plan for tomorrow or later has no
      // "now" to avoid scheduling into.
      notBeforeMinutes: widget.targetDate == dayKey(now)
          ? now.hour * 60 + now.minute
          : null,
      categories: categories,
    );
    setState(() {
      _generated = blocks;
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome, size: 17, color: c.primary),
                        const SizedBox(width: 8),
                        Text(l10n.planMyDay,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: c.text)),
                      ]),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: c.textDim)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _StepDots(step: _step, c: c),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: _step == 0
                    ? _buildPrioritiesStep(c, l10n)
                    : _step == 1
                        ? _buildCommitmentsStep(c, l10n)
                        : _buildReviewStep(c, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritiesStep(MeridianColors c, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.topPrioritiesQuestion,
            style: TextStyle(fontSize: 13.5, color: c.textDim)),
        const SizedBox(height: 14),
        for (var i = 0; i < _priorityCtrls.length; i++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FieldLabel(
                  '${l10n.priorityFieldLabel(i + 1)}${i == 0 ? '' : ' (${l10n.optionalLabel})'}',
                  c: c),
              if (i > 0)
                InkWell(
                  onTap: () => _removePriority(i),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child:
                        Icon(Icons.close, size: 14, color: c.textFaint),
                  ),
                ),
            ],
          ),
          MrdBidiTextField(
            controller: _priorityCtrls[i],
            style: TextStyle(color: c.text, fontSize: 13.5),
            decoration: mrdInputDecoration(c,
                hint: i == 0 ? l10n.priorityHint1 : l10n.optionalLabel),
            // BUG FIX: the "Continue" button's enabled state is derived
            // from _priorityCtrls[0].text, but without this callback
            // nothing ever told the widget to rebuild as the user typed —
            // the button stayed stuck on disabled forever, even after a
            // priority was entered, blocking the whole wizard.
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          _CategoryPicker(
            c: c,
            selected: _priorityCategories[i],
            onSelected: (cat) => setState(() => _priorityCategories[i] = cat),
          ),
          const SizedBox(height: 10),
        ],
        if (_priorityCtrls.length < _maxPriorities)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: _addPriority,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.textDim,
                side: BorderSide(color: c.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.add, size: 15),
              label: Text(l10n.addAnotherPriorityLabel,
                  style: const TextStyle(fontSize: 12.5)),
            ),
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _priorityCtrls[0].text.trim().isEmpty
              ? null
              : () => setState(() => _step = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.primaryInk,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
          child: Text(l10n.continueButton),
        ),
      ],
    );
  }

  // Null when the current priorities + hours-available combination fits
  // within the stated budget; otherwise the warning text to show under
  // the slider (see the comment at its call site for why this exists).
  String? _minimumTimeWarningText(MeridianColors c, AppLocalizations l10n) {
    final count = _priorityCtrls
        .map((ctrl) => ctrl.text.trim())
        .where((s) => s.isNotEmpty)
        .length;
    final neededMinutes = count * 30;
    final setMinutes = (_focusHours * 60).round();
    if (neededMinutes <= setMinutes) return null;
    return l10n.minimumTimeWarning(count, (neededMinutes / 60).toStringAsFixed(1),
        _focusHours.toStringAsFixed(1));
  }

  Widget _buildCommitmentsStep(MeridianColors c, AppLocalizations l10n) {
    final minTimeWarning = _minimumTimeWarningText(c, l10n);
    final unparsedCommitments =
        findUnparsedCommitmentLines(_commitmentsCtrl.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(l10n.fixedCommitmentsLabel, c: c),
        Text(l10n.commitmentsHintExample,
            style: TextStyle(fontSize: 11.5, color: c.textFaint)),
        const SizedBox(height: 8),
        MrdBidiTextField(
          controller: _commitmentsCtrl,
          maxLines: 4,
          style: TextStyle(color: c.text, fontSize: 13.5),
          decoration:
              mrdInputDecoration(c, hint: l10n.commitmentsFieldPlaceholder),
          onChanged: (_) => setState(() {}),
        ),
        if (unparsedCommitments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: c.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        l10n.unparsedCommitmentsWarning(
                            unparsedCommitments.join(', ')),
                        style: TextStyle(fontSize: 11.5, color: c.warning)),
                  ),
                ]),
          ),
        const SizedBox(height: 18),
        FieldLabel(
            l10n.hoursAvailableLabel(_focusHours.toStringAsFixed(1)),
            c: c),
        Slider(
          value: _focusHours,
          min: 1,
          max: 10,
          divisions: 18,
          activeColor: c.primary,
          inactiveColor: c.border,
          onChanged: (v) => setState(() => _focusHours = v),
        ),
        if (minTimeWarning != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: c.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(minTimeWarning,
                        style: TextStyle(fontSize: 11.5, color: c.warning)),
                  ),
                ]),
          ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.textDim,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text(l10n.backButton),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _goToReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.primaryInk,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(l10n.generateScheduleButton),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildReviewStep(MeridianColors c, AppLocalizations l10n) {
    final blocks = _generated ?? [];
    final noTimeLeftToday =
        blocks.isEmpty && widget.targetDate == dayKey(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            noTimeLeftToday
                ? l10n.noTimeLeftTodayMessage
                : l10n.blocksGeneratedReview(blocks.length),
            style: TextStyle(fontSize: 12.5, color: c.textDim)),
        const SizedBox(height: 12),
        ...blocks.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.text)),
                      Text(l10n.durationMinutesLabel(b.duration),
                          style: TextStyle(fontSize: 11.5, color: c.textFaint)),
                    ],
                  ),
                ),
              ]),
            )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.textDim,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text(l10n.backButton),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: blocks.isEmpty
                  ? null
                  : () {
                      widget.onApply(blocks);
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(l10n.addToMyDayButton),
            ),
          ),
        ]),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  final MeridianColors c;
  const _StepDots({required this.step, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == step;
          final done = i < step;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active || done ? c.primary : c.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

// A compact row of icon-only category chips so each priority can get a
// real category instead of the generator hardcoding one for every block
// (see the comment on `categories` in generateScheduleFromInputs) —
// deliberately icon+color only, no text labels, to fit under a single
// text field without pushing the wizard taller than one screen.
class _CategoryPicker extends StatelessWidget {
  final MeridianColors c;
  final TaskCategory selected;
  final ValueChanged<TaskCategory> onSelected;

  const _CategoryPicker(
      {required this.c, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kCategories.entries.map((e) {
        final isSelected = e.key == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message: categoryLabel(context, e.key),
            child: InkWell(
              onTap: () => onSelected(e.key),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? e.value.color.withValues(alpha: 0.18)
                      : c.surface,
                  border: Border.all(
                      color: isSelected ? e.value.color : c.border,
                      width: isSelected ? 1.4 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(e.value.icon,
                    size: 14,
                    color: isSelected ? e.value.color : c.textFaint),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
