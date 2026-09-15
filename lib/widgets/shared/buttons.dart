import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';

/// Ported from Buttons.tsx's <Pill>. A small toggle chip used for filters.
class MrdPill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final String label;
  final Color? dot;

  const MrdPill({super.key, required this.active, required this.onTap, required this.label, this.dot});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? c.primary : c.border),
            color: active ? c.primaryBg : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active ? c.primary : c.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ported from Buttons.tsx's <IconButton>. A labeled pill-shaped button.
class MrdIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool primary;
  final bool success;

  const MrdIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.primary = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final disabled = onTap == null;
    final borderColor = primary ? c.primary : success ? c.success : c.border;
    final bgColor = primary ? c.primary : success ? c.success.withValues(alpha: 0.14) : c.surface;
    final fgColor = primary ? c.primaryInk : success ? c.success : c.text;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              color: bgColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fgColor),
                const SizedBox(width: 7),
                Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fgColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ported from Buttons.tsx's <IconOnlyButton>. A bare icon action control.
class MrdIconOnlyButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final double size;
  final bool danger;
  // UI FIX (audit report #8): this whole widget's tap target used to be
  // the same 36x36 box as its visual footprint — under Android's
  // recommended 48dp minimum touch target. Three of these sit close
  // together on every habit card (edit / pause / delete), one of them
  // destructive, so a cramped hit target there is a real mis-tap risk,
  // not just a guideline nitpick. Same OverflowBox technique already
  // established in MrdCheckbox for exactly this problem: the tap target
  // grows, the visible icon and the surrounding layout (every Row that
  // already assumes this widget occupies 36x36) stay exactly as they
  // were — nothing shifts. Default is 44, not the full 48: with zero
  // gap between adjacent buttons (as on the habit card), overflowing
  // hit areas from neighboring buttons would start overlapping each
  // other past a certain size — 44 (4px of overflow per side) was
  // chosen together with the small gap added between the habit card's
  // three buttons (see habits_screen.dart) so neither button's tap
  // area encroaches on its neighbor's.
  final double tapTargetSize;

  const MrdIconOnlyButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.size = 15,
    this.danger = false,
    this.tapTargetSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final color = danger ? c.danger : c.textFaint;
    // BUG FIX (flutter analyze): `36` here is an int literal, and
    // `tapTargetSize` is a double — the ternary's inferred type was
    // `num`, not `double`, which OverflowBox's minWidth/minHeight/
    // maxWidth/maxHeight (typed `double?`) rejected outright. `36.0`
    // keeps both branches the same type.
    final hitSize = tapTargetSize > 36 ? tapTargetSize : 36.0;
    return Tooltip(
      message: label,
      child: SizedBox(
        width: 36,
        height: 36,
        child: OverflowBox(
          minWidth: hitSize,
          minHeight: hitSize,
          maxWidth: hitSize,
          maxHeight: hitSize,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(9),
              child: Center(child: Icon(icon, size: size, color: color)),
            ),
          ),
        ),
      ),
    );
  }
}
