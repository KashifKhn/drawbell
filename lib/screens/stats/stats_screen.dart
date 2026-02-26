import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/dismissal_record.dart';
import '../../providers/alarm_provider.dart';
import '../../theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DismissalRecord> stats = ref
        .watch(storageServiceProvider)
        .loadStats();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (stats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Morning Stats')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 80,
                  color: colors.onSurface.withAlpha(60),
                ),
                const SizedBox(height: 16),
                Text(
                  'No stats yet',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dismiss an alarm to see your stats',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int totalDismissals = stats.length;
    final double avgAttempts =
        stats
            .map((DismissalRecord r) => r.attempts)
            .reduce((int a, int b) => a + b) /
        totalDismissals;
    final int firstTryCount = stats
        .where((DismissalRecord r) => r.attempts == 0)
        .length;
    final double firstTryPct = totalDismissals > 0
        ? (firstTryCount / totalDismissals) * 100
        : 0;

    final Map<String, List<int>> categoryAttempts = {};
    for (final DismissalRecord r in stats) {
      categoryAttempts.putIfAbsent(r.category, () => []).add(r.attempts);
    }

    final List<MapEntry<String, double>> categoryAvg =
        categoryAttempts.entries.map((MapEntry<String, List<int>> e) {
          final double avg =
              e.value.reduce((int a, int b) => a + b) / e.value.length;
          return MapEntry(e.key, avg);
        }).toList()..sort(
          (MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value),
        );

    final List<MapEntry<String, double>> hardest = categoryAvg.take(5).toList();
    final List<MapEntry<String, double>> easiest = categoryAvg.reversed
        .take(5)
        .toList();

    final List<DismissalRecord> lastWeek = stats
        .where(
          (DismissalRecord r) => r.timestamp.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Stats'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _WeekDaySelector(stats: lastWeek, colors: colors),
          const SizedBox(height: 20),
          _AccuracyCard(
            firstTryPct: firstTryPct,
            avgAttempts: avgAttempts,
            totalDismissals: totalDismissals,
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: 16),
          _WakeUpTimeCard(
            stats: lastWeek,
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: 16),
          if (hardest.isNotEmpty) ...[
            _CategorySection(
              title: 'Hardest Categories',
              entries: hardest,
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
          ],
          if (easiest.isNotEmpty)
            _CategorySection(
              title: 'Easiest Categories',
              entries: easiest,
              colors: colors,
              textTheme: textTheme,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _WeekDaySelector extends StatelessWidget {
  final List<DismissalRecord> stats;
  final ColorScheme colors;

  const _WeekDaySelector({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (int i) {
        final int dayOffset = i - 2;
        final DateTime day = now.add(Duration(days: dayOffset));
        final bool isToday = dayOffset == 0;
        final List<String> dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
        final int displayWeekday = day.weekday;
        final String label = displayWeekday >= 1 && displayWeekday <= 5
            ? dayLabels[displayWeekday - 1]
            : displayWeekday == 6
            ? 'SAT'
            : 'SUN';

        return Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isToday ? AppTheme.brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : colors.onSurface,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  final double firstTryPct;
  final double avgAttempts;
  final int totalDismissals;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _AccuracyCard({
    required this.firstTryPct,
    required this.avgAttempts,
    required this.totalDismissals,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalDismissals total',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.brandOrange,
                      fontWeight: FontWeight.w600,
                    ),
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
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
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
                      _StatBar(
                        label: 'First-try',
                        value: '$firstTryPct%',
                        progress: firstTryPct / 100,
                        colors: colors,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 16),
                      _StatBar(
                        label: 'Avg attempts',
                        value: avgAttempts.toStringAsFixed(1),
                        progress: (1.0 / (avgAttempts + 1)).clamp(0.0, 1.0),
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
    final double strokeWidth = 10.0;
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

class _StatBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _StatBar({
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
                color: colors.onSurface,
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

class _WakeUpTimeCard extends StatelessWidget {
  final List<DismissalRecord> stats;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _WakeUpTimeCard({
    required this.stats,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    String lastWakeUp = '--:-- AM';
    if (stats.isNotEmpty) {
      final DismissalRecord latest = stats.last;
      lastWakeUp = DateFormat.jm().format(latest.timestamp);
    }

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
                  'Wake-up Time',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Weekly Avg',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  lastWakeUp,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: _WeekChart(stats: stats, colors: colors),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<DismissalRecord> stats;
  final ColorScheme colors;

  const _WeekChart({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    const List<String> labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final Map<int, int> dayCounts = {};
    for (final DismissalRecord r in stats) {
      final int wd = (r.timestamp.weekday - 1) % 7;
      dayCounts[wd] = (dayCounts[wd] ?? 0) + 1;
    }

    final int maxCount = dayCounts.values.isEmpty
        ? 1
        : dayCounts.values.reduce(max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (int i) {
        final int count = dayCounts[i] ?? 0;
        final double height = maxCount > 0 ? (count / maxCount) * 50 : 0;
        final bool isToday = (now.weekday - 1) % 7 == i;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 20,
              height: max(4.0, height),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.brandOrange
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppTheme.brandOrange : colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<MapEntry<String, double>> entries;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _CategorySection({
    required this.title,
    required this.entries,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.brandOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) Divider(height: 16, color: colors.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          entries[i].key,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${entries[i].value.toStringAsFixed(1)} avg',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
