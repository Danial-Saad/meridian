import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Ported from ConfirmDialog.tsx / useConfirm. Flutter's showDialog already
/// gives us the modal/backdrop/escape-to-cancel behavior for free, so this
/// is a thin helper that renders the same visual content as a native dialog.
Future<void> showMrdConfirm(
  BuildContext context, {
  required String title,
  String? description,
  String? confirmLabel,
  required VoidCallback onConfirm,
  // Every existing call site (delete task/habit/resource, reset data,
  // etc.) is a genuinely destructive action, so that's the default. The
  // exit-app confirmation is not destructive — passing false swaps the
  // red danger styling for the theme's normal accent color instead,
  // without touching how any existing caller looks.
  bool isDestructive = true,
  IconData icon = Icons.error_outline,
  IconData confirmIcon = Icons.delete_outline,
}) async {
  final c = context.read<ThemeController>().colors;
  final l10n = AppLocalizations.of(context)!;
  final resolvedConfirmLabel = confirmLabel ?? l10n.deleteLabel;
  final accent = isDestructive ? c.danger : c.primary;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: c.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: c.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(description, style: TextStyle(fontSize: 12.5, color: c.textDim)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(foregroundColor: c.textDim),
                  child: Text(l10n.cancelLabel),
                ),
                const SizedBox(width: 8),
                // BUG FIX: with no flex constraint here, a longer
                // confirmLabel (e.g. "Reset everything" vs the default
                // "Delete") could push this button past the dialog's
                // available width — a real RenderFlex overflow, not just a
                // cosmetic risk. Flexible lets it shrink instead, with
                // ellipsis as a safety net if it's ever tighter still.
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(confirmIcon, size: 15),
                    label: Text(resolvedConfirmLabel,
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed == true) onConfirm();
}
