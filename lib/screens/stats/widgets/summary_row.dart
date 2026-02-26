import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class SummaryRow extends StatelessWidget {
  final List<DismissalRecord> allStats;
  final List<DismissalRecord> lastWeekStats;

  const SummaryRow({
    super.key,
    required this.allStats,
    required this.lastWeekStats,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    String avgWakeUp = '--:--';
    String amPm = 'AM';
    String weekDelta = '';
    if (lastWeekStats.isNotEmpty) {
      final double avgMinutes =
          lastWeekStats
              .map(
                (DismissalRecord r) =>
                    r.timestamp.hour * 60 + r.timestamp.minute,
              )
              .reduce((int a, int b) => a + b) /
          lastWeekStats.length;
      final int hours = (avgMinutes ~/ 60) % 12;
      final int mins = avgMinutes.toInt() % 60;
      amPm = avgMinutes >= 720 ? 'PM' : 'AM';
      avgWakeUp =
          '${hours == 0 ? 12 : hours}:${mins.toString().padLeft(2, '0')}';

      final DateTime twoWeeksAgo = DateTime.now().subtract(
        const Duration(days: 14),
      );
      final DateTime oneWeekAgo = DateTime.now().subtract(
        const Duration(days: 7),
      );
      final List<DismissalRecord> prevWeek = allStats
          .where(
            (DismissalRecord r) =>
                r.timestamp.isAfter(twoWeeksAgo) &&
                r.timestamp.isBefore(oneWeekAgo),
          )
          .toList();
      if (prevWeek.isNotEmpty) {
        final double prevAvg =
            prevWeek
                .map(
                  (DismissalRecord r) =>
                      r.timestamp.hour * 60 + r.timestamp.minute,
                )
                .reduce((int a, int b) => a + b) /
            prevWeek.length;
        final int diff = (avgMinutes - prevAvg).round();
        if (diff != 0) {
          final String sign = diff > 0 ? '+' : '';
          weekDelta = '$sign${diff}m vs last week';
        }
      }
    }

    final int firstTryCount = allStats
        .where((DismissalRecord r) => r.attempts == 0)
        .length;
    final double successRate = allStats.isNotEmpty
        ? (firstTryCount / allStats.length) * 100
        : 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            icon: Icons.alarm,
            iconColor: AppTheme.brandOrange,
            label: 'AVG WAKE-UP',
            value: avgWakeUp,
            suffix: ' $amPm',
            subtitle: weekDelta,
            colors: colors,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            icon: Icons.check_circle,
            iconColor: AppTheme.brandOrange,
            label: 'SUCCESS RATE',
            value: '${successRate.toInt()}%',
            suffix: '',
            subtitle: '${allStats.length} total',
            colors: colors,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String suffix;
  final String subtitle;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.suffix,
    required this.subtitle,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
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
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  suffix,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
