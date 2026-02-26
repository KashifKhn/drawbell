import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class ConsistencyChart extends StatelessWidget {
  final List<DismissalRecord> weekStats;

  const ConsistencyChart({super.key, required this.weekStats});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String badge = _getBadge();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wake-up Consistency',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.brandOrange.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTheme.brandOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last 7 Days',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: Size.infinite,
                painter: _ConsistencyLinePainter(
                  stats: weekStats,
                  lineColor: AppTheme.brandOrange,
                  fillColor: AppTheme.brandOrange.withAlpha(30),
                  dotColor: colors.onSurface,
                  gridColor: colors.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final String label in const [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ])
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getBadge() {
    if (weekStats.isEmpty) return 'No Data';

    final double avgMinutes =
        weekStats
            .map(
              (DismissalRecord r) => r.timestamp.hour * 60 + r.timestamp.minute,
            )
            .reduce((int a, int b) => a + b) /
        weekStats.length;

    if (avgMinutes < 390) return 'Early Bird';
    if (avgMinutes < 480) return 'Morning Person';
    if (avgMinutes < 600) return 'Late Riser';
    return 'Night Owl';
  }
}

class _ConsistencyLinePainter extends CustomPainter {
  final List<DismissalRecord> stats;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color gridColor;

  _ConsistencyLinePainter({
    required this.stats,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;

    final Map<int, double> dayAvg = {};
    final Map<int, List<int>> dayMinutes = {};

    for (final DismissalRecord r in stats) {
      final int wd = (r.timestamp.weekday - 1) % 7;
      dayMinutes
          .putIfAbsent(wd, () => [])
          .add(r.timestamp.hour * 60 + r.timestamp.minute);
    }

    for (final MapEntry<int, List<int>> entry in dayMinutes.entries) {
      dayAvg[entry.key] =
          entry.value.reduce((int a, int b) => a + b) / entry.value.length;
    }

    if (dayAvg.isEmpty) return;

    final double minVal = dayAvg.values.reduce(min).toDouble() - 30;
    final double maxVal = dayAvg.values.reduce(max).toDouble() + 30;
    final double range = max(60, maxVal - minVal);

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i < 3; i++) {
      final double y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> points = [];
    final List<int> sortedDays = dayAvg.keys.toList()..sort();

    for (final int day in sortedDays) {
      final double x = (day / 6) * size.width;
      final double normalized = 1.0 - ((dayAvg[day]! - minVal) / range);
      final double y = normalized * size.height;
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    if (points.length >= 2) {
      final Path linePath = Path();
      linePath.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        final double cpx1 =
            points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 3;
        final double cpx2 =
            points[i].dx - (points[i].dx - points[i - 1].dx) / 3;
        linePath.cubicTo(
          cpx1,
          points[i - 1].dy,
          cpx2,
          points[i].dy,
          points[i].dx,
          points[i].dy,
        );
      }

      final Paint strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, strokePaint);

      final Path fillPath = Path.from(linePath);
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    for (final Offset point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(point, 2.5, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(_ConsistencyLinePainter old) => true;
}
