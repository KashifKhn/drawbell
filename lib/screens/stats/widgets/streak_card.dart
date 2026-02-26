import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class StreakCard extends StatelessWidget {
  final List<DismissalRecord> allStats;

  const StreakCard({super.key, required this.allStats});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final int streak = _calculateStreak();
    final int longestStreak = _calculateLongestStreak();
    final String level = _getLevel(streak);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandOrange.withAlpha(30),
              colors.surfaceContainerHighest,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandOrange.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.brandOrange.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: AppTheme.brandOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CURRENT STREAK',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.brandOrange,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$streak',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        streak == 1 ? 'Day' : 'Days',
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStreakEmoji(streak),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.brandOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandOrange.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getLevelIcon(streak),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StreakBadge(
                    label: level,
                    colors: colors,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Best: $longestStreak days',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateStreak() {
    if (allStats.isEmpty) return 0;

    final List<DismissalRecord> sorted = List.from(allStats)
      ..sort(
        (DismissalRecord a, DismissalRecord b) =>
            b.timestamp.compareTo(a.timestamp),
      );

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    final DateTime latestDate = DateTime(
      sorted.first.timestamp.year,
      sorted.first.timestamp.month,
      sorted.first.timestamp.day,
    );

    if (latestDate != today && latestDate != yesterday) return 0;

    int streak = 1;
    DateTime checkDate = latestDate.subtract(const Duration(days: 1));

    for (int i = 1; i < sorted.length; i++) {
      final DateTime recordDate = DateTime(
        sorted[i].timestamp.year,
        sorted[i].timestamp.month,
        sorted[i].timestamp.day,
      );

      if (recordDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (recordDate != latestDate &&
          recordDate != checkDate.add(const Duration(days: 1))) {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak() {
    if (allStats.isEmpty) return 0;

    final Set<DateTime> uniqueDays = allStats
        .map(
          (DismissalRecord r) =>
              DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day),
        )
        .toSet();

    final List<DateTime> sortedDays = uniqueDays.toList()..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final Duration diff = sortedDays[i].difference(sortedDays[i - 1]);
      if (diff.inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  String _getLevel(int streak) {
    if (streak >= 30) return 'Legend';
    if (streak >= 14) return 'On Fire';
    if (streak >= 7) return 'Consistent';
    if (streak >= 3) return 'Building Up';
    return 'Getting Started';
  }

  String _getStreakEmoji(int streak) {
    if (streak >= 30) return '\u{1F525}';
    if (streak >= 14) return '\u{1F525}';
    if (streak >= 7) return '\u{1F525}';
    if (streak >= 3) return '\u{1F525}';
    return '\u{1F525}';
  }

  IconData _getLevelIcon(int streak) {
    if (streak >= 30) return Icons.diamond;
    if (streak >= 14) return Icons.emoji_events;
    if (streak >= 7) return Icons.star;
    if (streak >= 3) return Icons.bolt;
    return Icons.local_fire_department;
  }
}

class _StreakBadge extends StatelessWidget {
  final String label;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _StreakBadge({
    required this.label,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: AppTheme.brandOrange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
