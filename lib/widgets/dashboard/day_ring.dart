import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/geometry_utils.dart';

/// Ported from the DayRing function inside DashboardScreen.tsx — the app's
/// signature element. Period-of-day arcs on the outside (night / morning /
/// afternoon / evening), task arcs on the inside sized by actual start time
/// and duration, and a pulsing "now" marker at the current time of day.
class MeridianDayRingCard extends StatefulWidget {
  final List<Task> tasks;
  final DayStats stats;

  const MeridianDayRingCard(
      {super.key, required this.tasks, required this.stats});

  @override
  State<MeridianDayRingCard> createState() => _MeridianDayRingCardState();
}

class _MeridianDayRingCardState extends State<MeridianDayRingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surface, c.bgElevated]),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => CustomPaint(
                painter: _DayRingPainter(
                  tasks: widget.tasks,
                  now: now,
                  stats: widget.stats,
                  c: c,
                  pulse: _pulseCtrl.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${widget.stats.pct}%',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: c.text)),
                      const SizedBox(height: 4),
                      Text(
                          l10n.tasksDoneLabel(
                              widget.stats.completed, widget.stats.total),
                          style: TextStyle(fontSize: 12, color: c.textDim)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legendDot(c.periodMorning, l10n.periodMorning, c),
              _legendDot(c.periodAfternoon, l10n.periodAfternoon, c),
              _legendDot(c.periodEvening, l10n.periodEvening, c),
              _legendDot(c.periodNight, l10n.periodNight, c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, MeridianColors c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10.5, color: c.textFaint)),
      ]);
}

class _Period {
  final double from;
  final double to;
  final Color Function(MeridianColors) colorOf;
  const _Period(this.from, this.to, this.colorOf);
}

final _periods = <_Period>[
  _Period(0, 6, (c) => c.periodNight),
  _Period(6, 12, (c) => c.periodMorning),
  _Period(12, 17, (c) => c.periodAfternoon),
  _Period(17, 21, (c) => c.periodEvening),
  _Period(21, 24, (c) => c.periodNight),
];

class _DayRingPainter extends CustomPainter {
  final List<Task> tasks;
  final DateTime now;
  final DayStats stats;
  final MeridianColors c;
  final double pulse;

  _DayRingPainter(
      {required this.tasks,
      required this.now,
      required this.stats,
      required this.c,
      required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 300;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = 118.0 * scale;
    final taskR = 96.0 * scale;

    for (final p in _periods) {
      final (start, sweep) = arcRadians(hourToAngle(p.from), hourToAngle(p.to));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerR),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * scale
          ..strokeCap = StrokeCap.round
          ..color = p.colorOf(c).withValues(alpha: 0.4),
      );
    }

    for (final t in tasks) {
      final startHour = t.start / 60;
      final endHour = (t.start + t.duration) / 60;
      final color = kCategories[t.category]?.color ?? c.primary;
      final isSkipped = t.status == TaskStatus.skipped;
      final isCompleted = t.status == TaskStatus.completed;
      final (start, sweep) =
          arcRadians(hourToAngle(startHour), hourToAngle(endHour));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * scale
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(
            alpha: isCompleted
                ? 1
                : isSkipped
                    ? 0.3
                    : 0.5);
      if (isSkipped) {
        _drawDashedArc(canvas, center, taskR, start, sweep, paint);
      } else {
        canvas.drawArc(Rect.fromCircle(center: center, radius: taskR), start,
            sweep, false, paint);
      }
    }

    final nowHours = now.hour + now.minute / 60;
    final nowPoint =
        polarToCartesian(center.dx, center.dy, outerR, hourToAngle(nowHours));

    // Pulsing ring around the "now" dot.
    final pulseR = (9 + pulse * 6) * scale;
    final pulseOpacity = clampDouble(0.6 * (1 - pulse), 0.0, 0.6);
    canvas.drawCircle(
      nowPoint,
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale
        ..color = c.primary.withValues(alpha: pulseOpacity),
    );

    canvas.drawCircle(nowPoint, 5 * scale, Paint()..color = c.text);
  }

  void _drawDashedArc(Canvas canvas, Offset center, double radius,
      double startRad, double sweepRad, Paint paint) {
    const dashLen = 0.08;
    const gapLen = 0.06;
    var covered = 0.0;
    final total = sweepRad.abs();
    final dir = sweepRad.isNegative ? -1 : 1;
    while (covered < total) {
      final segLen = (dashLen < total - covered) ? dashLen : total - covered;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startRad + dir * covered, dir * segLen, false, paint);
      covered += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _DayRingPainter oldDelegate) => true;
}
