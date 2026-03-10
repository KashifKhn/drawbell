import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class DailyAlarmStatsCard extends StatelessWidget {
  final List<DismissalRecord> allStats;

  const DailyAlarmStatsCard({super.key, required this.allStats});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();

    final List<DismissalRecord> todayStats =
        allStats
            .where(
              (DismissalRecord record) =>
                  record.timestamp.year == now.year &&
                  record.timestamp.month == now.month &&
                  record.timestamp.day == now.day,
            )
            .toList()
          ..sort(
            (DismissalRecord a, DismissalRecord b) =>
                a.timestamp.compareTo(b.timestamp),
          );

    final int dismissals = todayStats.length;
    final int firstTryDismissals = todayStats
        .where((DismissalRecord record) => record.attempts == 0)
        .length;
    final double averageAttempts = dismissals > 0
        ? todayStats
                  .map((DismissalRecord record) => record.attempts + 1)
                  .reduce((int a, int b) => a + b) /
              dismissals
        : 0;
    final double averageDuration = dismissals > 0
        ? todayStats
                  .map((DismissalRecord record) => record.durationSeconds)
                  .reduce((int a, int b) => a + b) /
              dismissals
        : 0;
    final double averageConfidence = dismissals > 0
        ? todayStats
                  .map((DismissalRecord record) => record.confidence)
                  .reduce((double a, double b) => a + b) /
              dismissals
        : 0;

    final String lastDismissal = dismissals > 0
        ? _formatTime(todayStats.last.timestamp)
        : '--:--';

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
                  'Daily Alarm Stats',
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
                  ),
                  child: Text(
                    'Today',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTheme.brandOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dismissals == 0
                  ? 'No dismissals yet today'
                  : 'Last dismissal at $lastDismissal',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Dismissed',
                    value: '$dismissals',
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'First try',
                    value: '$firstTryDismissals',
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Avg attempts',
                    value: dismissals == 0
                        ? '--'
                        : averageAttempts.toStringAsFixed(1),
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Avg duration',
                    value: dismissals == 0
                        ? '--'
                        : '${averageDuration.toStringAsFixed(0)}s',
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricTile(
              label: 'Avg confidence',
              value: dismissals == 0
                  ? '--'
                  : '${(averageConfidence * 100).toStringAsFixed(0)}%',
              colors: colors,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
