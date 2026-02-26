import 'package:flutter/material.dart';

import '../../../theme.dart';

class WeekDaySelector extends StatelessWidget {
  final int activeDayOffset;

  const WeekDaySelector({super.key, this.activeDayOffset = 0});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (int i) {
        final int dayOffset = i - 2;
        final DateTime day = now.add(Duration(days: dayOffset));
        final bool isToday = dayOffset == activeDayOffset;
        final String label = _weekdayLabel(day.weekday);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isToday ? AppTheme.brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isToday ? Colors.white : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 18,
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

  String _weekdayLabel(int weekday) {
    const List<String> labels = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
    return labels[weekday - 1];
  }
}
