import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class MrdCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final double size;
  // UX FIX: the checkbox's *visual* size used to also be its entire tap
  // target — 15-19 logical px depending on screen, well under Android's
  // recommended 48dp / iOS's 44pt minimum touch target. This is the single
  // most frequent interaction in the app (marking a task/habit done), so a
  // fiddly hit target here matters more than almost anywhere else.
  // tapTargetSize adds invisible hit-area padding around the same visual
  // box via OverflowBox — the checkbox still looks exactly as before, and
  // the parent Row's layout is unaffected (OverflowBox reports the
  // original `size` upward, then paints/hit-tests the larger area on top
  // of neighboring content). Screens with less room to spare (the Planner
  // grid) can pass a smaller override; see call sites.
  final double tapTargetSize;

  const MrdCheckbox({
    super.key,
    required this.checked,
    required this.onTap,
    this.size = 18,
    this.tapTargetSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final hitSize = tapTargetSize > size ? tapTargetSize : size;
    final visual = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? c.success : c.border, width: 1.5),
        color: checked ? c.success : Colors.transparent,
      ),
      child: checked ? Icon(Icons.check, size: size * 0.66, color: c.bg) : null,
    );
    return Semantics(
      label: checked ? l10n.statusCompleted : l10n.notCompletedSemanticLabel,
      hint: checked ? l10n.doubleTapMarkNotDone : l10n.doubleTapMarkDone,
      button: true,
      toggled: checked,
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          minWidth: hitSize,
          minHeight: hitSize,
          maxWidth: hitSize,
          maxHeight: hitSize,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: ExcludeSemantics(child: Center(child: visual)),
            ),
          ),
        ),
      ),
    );
  }
}
