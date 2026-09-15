import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  // Pre-formatted trend text (e.g. "+12m vs yesterday"). Direction is
  // passed separately rather than parsed from the string so the arrow
  // and color are always right regardless of locale/formatting.
  final String? trendText;
  final bool? trendUp; // true: up/green, false: down/red, null: neutral/gray

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.trendText,
    this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final trendColor =
        trendUp == null ? c.textFaint : (trendUp! ? c.success : c.danger);
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
        color: c.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.textFaint),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: c.textDim)),
          if (trendText != null) ...[
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  trendUp == null
                      ? Icons.remove
                      : (trendUp! ? Icons.arrow_upward : Icons.arrow_downward),
                  size: 11,
                  color: trendColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(trendText!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: trendColor,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }
}
