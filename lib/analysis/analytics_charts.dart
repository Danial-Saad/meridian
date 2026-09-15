import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/domain.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../utils/geometry_utils.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const ChartCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16),
          color: c.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class TodayFocusBreakdown extends StatelessWidget {
  final int minutes;
  const TodayFocusBreakdown({super.key, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    const target = 240;
    final pct = clampInt(((minutes / target) * 100).round(), 0, 100);
    if (minutes == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Icon(Icons.access_time, size: 20, color: c.textFaint),
          const SizedBox(height: 8),
          Text(l10n.noFocusSessionsToday,
              style: TextStyle(fontSize: 12.5, color: c.textFaint)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${minutes ~/ 60}h ${minutes % 60}m',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
              const SizedBox(width: 8),
              Text(l10n.ofFocusTarget(target ~/ 60),
                  style: TextStyle(fontSize: 11.5, color: c.textFaint)),
            ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 10,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation(c.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.pctOfTodaysTarget(pct),
            style: TextStyle(fontSize: 11, color: c.textFaint)),
      ],
    );
  }
}

class FocusAreaChart extends StatefulWidget {
  final List<HistoryDay> data;
  const FocusAreaChart({super.key, required this.data});

  @override
  State<FocusAreaChart> createState() => _FocusAreaChartState();
}

class _FocusAreaChartState extends State<FocusAreaChart> {
  int? _active;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final activeIndex = _active ?? (data.isNotEmpty ? data.length - 1 : null);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const h = 170.0;
      return GestureDetector(
        onTapDown: (details) {
          if (data.isEmpty) return;
          final stepX = data.length > 1 ? (w - 24) / (data.length - 1) : 0;
          final idx = stepX > 0
              ? clampInt(((details.localPosition.dx - 12) / stepX).round(), 0,
                  data.length - 1)
              : 0;
          setState(() => _active = idx);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: w,
              height: h,
              child: CustomPaint(
                  painter: _FocusAreaPainter(
                      data: data, c: c, activeIndex: activeIndex)),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _xLabels(data, l10n)
                  .map((l) => Text(l,
                      style: TextStyle(fontSize: 9.5, color: c.textFaint)))
                  .toList(),
            ),
            if (activeIndex != null && data.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.minPerDayPoint(data[activeIndex].focusMinutes,
                      fmtDateShort(
                          parseDayKey(data[activeIndex].date), l10n)),
                  style: TextStyle(
                      fontSize: 11.5,
                      color: c.text,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<String> _xLabels(List<HistoryDay> data, AppLocalizations l10n) {
    if (data.isEmpty) return [];
    final step = data.length <= 8 ? 1 : (data.length / 6).ceil();
    final labels = <String>[];
    for (var i = 0; i < data.length; i += step) {
      labels.add(fmtDateShort(parseDayKey(data[i].date), l10n));
    }
    return labels;
  }
}

class _FocusAreaPainter extends CustomPainter {
  final List<HistoryDay> data;
  final MeridianColors c;
  final int? activeIndex;
  _FocusAreaPainter({required this.data, required this.c, this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const pad = 12.0;
    final w = size.width;
    final h = size.height;
    final maxVal =
        data.map((d) => d.focusMinutes).fold<int>(60, (a, b) => a > b ? a : b);
    final stepX = data.length > 1 ? (w - pad * 2) / (data.length - 1) : 0.0;

    final points = List.generate(data.length, (i) {
      final x = pad + i * stepX;
      final y = h - pad - (data[i].focusMinutes / maxVal) * (h - pad * 2 - 10);
      return Offset(x, y);
    });

    final gridPaint = Paint()
      ..color = c.border
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = h - pad - f * (h - pad * 2 - 10);
      _dashedLine(canvas, Offset(pad, y), Offset(w - pad, y), gridPaint);
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, 3, Paint()..color = c.primary);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final midX = (prev.dx + cur.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, h - pad)
      ..lineTo(points.first.dx, h - pad)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.primary.withValues(alpha: 0.35), c.primary.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = c.primary,
    );

    for (var i = 0; i < points.length; i++) {
      final isActive = i == activeIndex;
      canvas.drawCircle(
          points[i], isActive ? 5 : 3, Paint()..color = c.bgElevated);
      canvas.drawCircle(
        points[i],
        isActive ? 5 : 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c.primary,
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 3.0, dashSpace = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * clampDouble(dist + dashWidth, 0, total);
      canvas.drawLine(start, end, paint);
      dist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _FocusAreaPainter old) =>
      old.data != data || old.activeIndex != activeIndex || old.c != c;
}

class CategoryDatum {
  final String id;
  final String label;
  final Color color;
  final int count;
  final int pct;
  const CategoryDatum(
      {required this.id,
      required this.label,
      required this.color,
      required this.count,
      required this.pct});
}

class DonutChart extends StatelessWidget {
  final List<CategoryDatum> data;
  const DonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
            child: Text(l10n.noTasksYet,
                style: TextStyle(fontSize: 13, color: c.textFaint))),
      );
    }
    final total = data.fold<int>(0, (s, d) => s + d.count);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
              painter: _DonutPainter(
                  data: data, total: total, trackColor: c.border),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  Text(l10n.tasksWord,
                      style: TextStyle(fontSize: 9.5, color: c.textFaint)),
                ]),
              )),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: data
              .map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: d.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(d.label,
                          style: TextStyle(fontSize: 12, color: c.textDim)),
                      const SizedBox(width: 8),
                      Text('${d.pct}%',
                          style: TextStyle(fontSize: 11.5, color: c.textFaint)),
                    ]),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryDatum> data;
  final int total;
  final Color trackColor;
  _DonutPainter(
      {required this.data, required this.total, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = trackColor);

    var cumulative = 0;
    final effectiveTotal = total == 0 ? 1 : total;
    for (final d in data) {
      final startDeg = (cumulative / effectiveTotal) * 360;
      cumulative += d.count;
      final endDeg = (cumulative / effectiveTotal) * 360;
      final (start, sweep) = arcRadians(startDeg, endDeg);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = data.length > 1 ? StrokeCap.butt : StrokeCap.round
          ..color = d.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.data != data;
}

class CompletionBarChart extends StatelessWidget {
  final List<HistoryDay> data;
  const CompletionBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(painter: _BarPainter(data: data, c: c)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _legendDot(c.success, l10n.statusCompleted, c),
          const SizedBox(width: 16),
          _legendDot(c.danger, l10n.statusSkipped, c),
        ]),
      ],
    );
  }

  Widget _legendDot(Color color, String label, MeridianColors c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, color: c.textDim)),
      ]);
}

class _BarPainter extends CustomPainter {
  final List<HistoryDay> data;
  final MeridianColors c;
  _BarPainter({required this.data, required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const pad = 12.0;
    final w = size.width;
    final h = size.height;
    final maxVal =
        data.map((d) => d.totalTasks).fold<int>(4, (a, b) => a > b ? a : b);
    final groupW = (w - pad * 2) / data.length;
    final barW = (groupW * 0.28).clamp(0, 16).toDouble();

    final gridPaint = Paint()
      ..color = c.border
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = h - pad - f * (h - pad * 2);
      _dashedLine(canvas, Offset(pad, y), Offset(w - pad, y), gridPaint);
    }

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final groupX = pad + i * groupW + groupW / 2;
      final completedH = (d.completed / maxVal) * (h - pad * 2);
      final skippedH = (d.skipped / maxVal) * (h - pad * 2);

      final completedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            groupX - barW - 2, h - pad - completedH, barW, completedH),
        const Radius.circular(3),
      );
      canvas.drawRRect(
          completedRect, Paint()..color = c.success.withValues(alpha: 0.85));

      final skippedHeight = skippedH < 1 ? 1.0 : skippedH;
      final skippedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(groupX + 2, h - pad - skippedHeight, barW, skippedHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(skippedRect, Paint()..color = c.danger.withValues(alpha: 0.6));
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 3.0, dashSpace = 5.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * clampDouble(dist + dashWidth, 0, total);
      canvas.drawLine(start, end, paint);
      dist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.data != data;
}

class WeeklyHabitStrip extends StatelessWidget {
  final List<HabitWithStats> habits;
  const WeeklyHabitStrip({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text(AppLocalizations.of(context)!.noHabitsYetShort,
                style: TextStyle(fontSize: 13, color: c.textFaint))),
      );
    }
    return Column(
      children: habits.map((h) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
                width: 22,
                child: Text(h.emoji, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: h.last7
                    .map((done) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 20,
                            decoration: BoxDecoration(
                              color: done
                                  ? hexToColor(h.color).withValues(alpha: 0.85)
                                  : c.border,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// --- FEATURE 1: Advanced Productivity Progress Widget ---
class AdvancedProgressOverview extends StatelessWidget {
  final int completed;
  final int total;
  final int habitConsistency;
  // GAP CLOSED (GHADI_DEVELOPMENT.md Feature Conflict Check, item #1 —
  // "planned vs actual time" was listed as still missing): plannedMinutes
  // is the sum of every task's planned `duration` for the selected range;
  // actualMinutes is that range's real focus time (completed-task duration
  // + logged Focus Mode sessions, via the Discrepancy #3 fix in
  // `store/history.dart`). Both are computed range-aware in
  // `analytics_screen.dart` from the same date-window as everything else
  // on the screen.
  final int plannedMinutes;
  final int actualMinutes;

  const AdvancedProgressOverview(
      {super.key,
      required this.completed,
      required this.total,
      required this.habitConsistency,
      required this.plannedMinutes,
      required this.actualMinutes});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final taskPct = total > 0 ? ((completed / total) * 100).round() : 0;
    final timePct = plannedMinutes > 0
        ? clampInt(((actualMinutes / plannedMinutes) * 100).round(), 0, 100)
        : (actualMinutes > 0 ? 100 : 0);
    return Column(
      children: [
        _buildBar(context, c, l10n.plannedVsCompletedLabel(completed, total),
            taskPct, c.primary),
        const SizedBox(height: 16),
        _buildBar(context, c, l10n.avgHabitConsistencyLabel, habitConsistency,
            c.success),
        const SizedBox(height: 16),
        _buildBar(
            context,
            c,
            l10n.plannedVsActualTimeLabel(fmtDurationShort(plannedMinutes),
                fmtDurationShort(actualMinutes)),
            timePct,
            c.warning),
      ],
    );
  }

  Widget _buildBar(BuildContext context, MeridianColors c, String label,
      int pct, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: c.textDim)),
        Text('$pct%',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct / 100,
          minHeight: 8,
          backgroundColor: c.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}
// --------------------------------------------------------
