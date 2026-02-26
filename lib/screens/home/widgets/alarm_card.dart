import 'package:flutter/material.dart';

import '../../../core/utils.dart';
import '../../../models/alarm_model.dart';
import '../../../theme.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double disabledAlpha = alarm.isEnabled ? 1.0 : 0.45;

    return Dismissible(
      key: ValueKey<String>(alarm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colors.onError),
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _TimeDisplay(
                        time: alarm.time,
                        alpha: disabledAlpha,
                        textTheme: textTheme,
                        colors: colors,
                      ),
                    ),
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: (bool value) => onToggle(value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CategoryBadge(alarm: alarm, alpha: disabledAlpha),
                    const SizedBox(width: 12),
                    if (alarm.scheduledDate != null)
                      Opacity(
                        opacity: disabledAlpha,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatScheduledDate(alarm.scheduledDate!),
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Opacity(
                        opacity: disabledAlpha,
                        child: Text(
                          formatDays(alarm.repeatDays),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final TimeOfDay time;
  final double alpha;
  final TextTheme textTheme;
  final ColorScheme colors;

  const _TimeDisplay({
    required this.time,
    required this.alpha,
    required this.textTheme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final String hour = time.hourOfPeriod == 0
        ? '12'
        : time.hourOfPeriod.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return Opacity(
      opacity: alpha,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$hour:$minute',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              fontSize: 36,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              period,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final AlarmModel alarm;
  final double alpha;

  const _CategoryBadge({required this.alarm, required this.alpha});

  @override
  Widget build(BuildContext context) {
    final String categoryText = alarm.categories.isNotEmpty
        ? alarm.categories.first
        : 'Random';
    final String label =
        '${_capitalize(categoryText)} (${alarm.difficulty.label})';

    return Opacity(
      opacity: alpha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.brandOrange.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 12, color: AppTheme.brandOrange),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}
