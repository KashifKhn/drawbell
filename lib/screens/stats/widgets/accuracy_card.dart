import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class AccuracyCard extends StatelessWidget {
  final List<DismissalRecord> allStats;

  const AccuracyCard({super.key, required this.allStats});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final int firstTryCount = allStats
        .where((DismissalRecord r) => r.attempts == 0)
        .length;
    final double firstTryPct = allStats.isNotEmpty
        ? (firstTryCount / allStats.length) * 100
        : 0;

    final double avgConfidence = allStats.isNotEmpty
        ? allStats
                  .map((DismissalRecord r) => r.confidence)
                  .reduce((double a, double b) => a + b) /
              allStats.length *
              100
        : 0;

    final double avgDuration = allStats.isNotEmpty
        ? allStats
                  .map((DismissalRecord r) => r.durationSeconds)
                  .reduce((int a, int b) => a + b) /
              allStats.length
        : 0;

    final double weekDelta = _getWeeklyDelta();

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
                  'Drawing Accuracy',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                if (weekDelta != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: weekDelta > 0
                          ? const Color(0xFF1B5E20).withAlpha(40)
                          : colors.error.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          weekDelta > 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 14,
                          color: weekDelta > 0
                              ? const Color(0xFF4CAF50)
                              : colors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${weekDelta > 0 ? '+' : ''}${weekDelta.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: weekDelta > 0
                                ? const Color(0xFF4CAF50)
                                : colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI Recognition Score',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _RingPainter(
                      percentage: firstTryPct / 100,
                      color: AppTheme.brandOrange,
                      bgColor: colors.surfaceContainer,
                    ),
                    child: Center(
                      child: Text(
                        '${firstTryPct.toInt()}%',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricBar(
                        label: 'Speed',
                        value: '${avgDuration.toInt()}s',
                        progress: (1.0 - (avgDuration / 60)).clamp(0.0, 1.0),
                        colors: colors,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 20),
                      _MetricBar(
                        label: 'Precision',
                        value: '${avgConfidence.toInt()}%',
                        progress: (avgConfidence / 100).clamp(0.0, 1.0),
                        colors: colors,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getWeeklyDelta() {
    if (allStats.length < 2) return 0;

    final DateTime oneWeekAgo = DateTime.now().subtract(
      const Duration(days: 7),
    );
    final DateTime twoWeeksAgo = DateTime.now().subtract(
      const Duration(days: 14),
    );

    final List<DismissalRecord> thisWeek = allStats
        .where((DismissalRecord r) => r.timestamp.isAfter(oneWeekAgo))
        .toList();
    final List<DismissalRecord> lastWeek = allStats
        .where(
          (DismissalRecord r) =>
              r.timestamp.isAfter(twoWeeksAgo) &&
              r.timestamp.isBefore(oneWeekAgo),
        )
        .toList();

    if (thisWeek.isEmpty || lastWeek.isEmpty) return 0;

    final double thisRate =
        thisWeek.where((DismissalRecord r) => r.attempts == 0).length /
        thisWeek.length *
        100;
    final double lastRate =
        lastWeek.where((DismissalRecord r) => r.attempts == 0).length /
        lastWeek.length *
        100;

    return thisRate - lastRate;
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  _RingPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 10.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    final Paint bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percentage != percentage;
}

class _MetricBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandOrange),
          ),
        ),
      ],
    );
  }
}
