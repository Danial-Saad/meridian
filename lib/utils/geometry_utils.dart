import 'dart:math' as math;
import 'dart:ui';

/// Ported from geometry.ts — used by CustomPainters that draw the Day Ring
/// and the Analytics donut chart as arcs, mirroring the original SVG paths.
Offset polarToCartesian(double cx, double cy, double r, double angleDeg) {
  final a = (angleDeg - 90) * math.pi / 180;
  return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
}

double hourToAngle(double hour) => (hour / 24) * 360;

/// Sweep angle helpers for Flutter's Canvas.drawArc, which wants a start
/// angle and a sweep in radians measured clockwise from the 3 o'clock
/// position — different conventions than the SVG path-based describeArc()
/// in the original, so this returns (startRadians, sweepRadians) instead.
(double, double) arcRadians(double startAngleDeg, double endAngleDeg) {
  final start = (startAngleDeg - 90) * math.pi / 180;
  final sweep = (endAngleDeg - startAngleDeg) * math.pi / 180;
  return (start, sweep);
}
