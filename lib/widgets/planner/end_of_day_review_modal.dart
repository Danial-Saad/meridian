import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';
import '../shared/field_label.dart';
import '../shared/mrd_bidi_text_field.dart';

/// Ported from EndOfDayReviewModal.tsx — shows the day's numbers, then two
/// free-text reflection fields, saved as a DailyReview keyed by dayKey.
Future<void> showEndOfDayReviewModal(
  BuildContext context, {
  required DayStats stats,
  required int habitsCompleted,
  required int habitsTotal,
  required void Function(String wentWell, String improve) onSave,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EndOfDayReviewSheet(
      stats: stats,
      habitsCompleted: habitsCompleted,
      habitsTotal: habitsTotal,
      onSave: onSave,
    ),
  );
}

class EndOfDayReviewSheet extends StatefulWidget {
  final DayStats stats;
  final int habitsCompleted;
  final int habitsTotal;
  final void Function(String wentWell, String improve) onSave;

  const EndOfDayReviewSheet({
    super.key,
    required this.stats,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.onSave,
  });

  @override
  State<EndOfDayReviewSheet> createState() => _EndOfDayReviewSheetState();
}

class _EndOfDayReviewSheetState extends State<EndOfDayReviewSheet> {
  final _wentWellCtrl = TextEditingController();
  final _improveCtrl = TextEditingController();

  @override
  void dispose() {
    _wentWellCtrl.dispose();
    _improveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.nightlight_round, size: 17, color: c.primary),
                    const SizedBox(width: 8),
                    Text(l10n.endOfDayReviewTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
                  ]),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, color: c.textDim)),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: [
                _reviewStat(c, '${widget.stats.completed}/${widget.stats.actionable}', l10n.tasksDoneStatLabel),
                const SizedBox(width: 10),
                _reviewStat(c, '${widget.stats.focusMinutes}m', l10n.focusedStatLabel),
                const SizedBox(width: 10),
                _reviewStat(c, '${widget.habitsCompleted}/${widget.habitsTotal}', l10n.habitsTitle),
              ]),
              const SizedBox(height: 18),
              FieldLabel(l10n.whatWentWellLabel, c: c),
              MrdBidiTextField(
                controller: _wentWellCtrl,
                maxLines: 3,
                style: TextStyle(color: c.text, fontSize: 13.5),
                decoration: mrdInputDecoration(c, hint: l10n.optionalLabel),
              ),
              const SizedBox(height: 14),
              FieldLabel(l10n.whatCouldImproveLabel, c: c),
              MrdBidiTextField(
                controller: _improveCtrl,
                maxLines: 3,
                style: TextStyle(color: c.text, fontSize: 13.5),
                decoration: mrdInputDecoration(c, hint: l10n.optionalLabel),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.onSave(_wentWellCtrl.text.trim(), _improveCtrl.text.trim());
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.primaryInk,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(l10n.saveReflectionButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewStat(MeridianColors c, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: c.textDim)),
        ]),
      ),
    );
  }
}
