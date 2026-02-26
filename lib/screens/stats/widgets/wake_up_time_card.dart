import 'dart:math';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class WakeUpTimeCard extends StatelessWidget {
  final List<DismissalRecord> weekStats;
  final TimeOfDay? targetTime;

  const WakeUpTimeCard({super.key, required this.weekStats, this.targetTime});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    String lastWakeUp = '--:--';
    String amPm = 'AM';
    if (weekStats.isNotEmpty) {
      final DismissalRecord latest = weekStats.last;
      final String formatted = DateFormat.jm().format(latest.timestamp);
      final List<String> parts = formatted.split(' ');
      lastWakeUp = parts[0];
      amPm = parts.length > 1 ? parts[1] : '';
    }

    final String targetLabel = targetTime != null
        ? 'Target: ${_formatTimeOfDay(targetTime!)}'
        : '';

    double weeklyAvgMinutes = 0;
    if (weekStats.isNotEmpty) {
      weeklyAvgMinutes =
          weekStats
              .map(
                (DismissalRecord r) =>
                    r.timestamp.hour * 60 + r.timestamp.minute,
              )
              .reduce((int a, int b) => a + b) /
          weekStats.length;
    }
    final String weeklyAvgLabel = weekStats.isNotEmpty
        ? _formatMinutes(weeklyAvgMinutes)
        : '--:-- AM';

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Avg $weeklyAvgLabel',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (targetLabel.isNotEmpty)
                      Text(
                        targetLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
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
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandOrange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  amPm,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.brandOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: _WakeUpBarChart(
                stats: weekStats,
                colors: colors,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final int h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String m = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formatMinutes(double totalMinutes) {
    final int hours = (totalMinutes ~/ 60) % 12;
    final int mins = totalMinutes.toInt() % 60;
    final String period = totalMinutes >= 720 ? 'PM' : 'AM';
    return '${hours == 0 ? 12 : hours}:${mins.toString().padLeft(2, '0')} $period';
  }
}

class _WakeUpBarChart extends StatelessWidget {
  final List<DismissalRecord> stats;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _WakeUpBarChart({
    required this.stats,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    const List<String> labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final Map<int, List<int>> dayMinutes = {};
    for (final DismissalRecord r in stats) {
      final int wd = (r.timestamp.weekday - 1) % 7;
      dayMinutes
          .putIfAbsent(wd, () => [])
          .add(r.timestamp.hour * 60 + r.timestamp.minute);
    }

    int minMinute = 360;
    int maxMinute = 540;
    for (final List<int> mins in dayMinutes.values) {
      for (final int m in mins) {
        if (m < minMinute) minMinute = m;
        if (m > maxMinute) maxMinute = m;
      }
    }
    minMinute = (minMinute ~/ 60) * 60;
    maxMinute = ((maxMinute ~/ 60) + 1) * 60;
    final int range = max(60, maxMinute - minMinute);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatHour(minMinute),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            Text(
              _formatHour((minMinute + maxMinute) ~/ 2),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            Text(
              _formatHour(maxMinute),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (int i) {
              final List<int> mins = dayMinutes[i] ?? [];
              final bool isToday = (now.weekday - 1) % 7 == i;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final int m in mins)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Container(
                              width: 24,
                              height: max(4.0, ((m - minMinute) / range) * 40),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppTheme.brandOrange
                                    : AppTheme.brandOrange.withAlpha(100),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        if (mins.isEmpty)
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? AppTheme.brandOrange
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  String _formatHour(int totalMinutes) {
    final int h = (totalMinutes ~/ 60) % 12;
    return '${h == 0 ? 12 : h}:${(totalMinutes % 60).toString().padLeft(2, '0')}';
  }
}
