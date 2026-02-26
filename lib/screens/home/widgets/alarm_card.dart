import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../models/alarm_model.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatTimeOfDay(alarm.time),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: alarm.isEnabled
                              ? colors.onSurface
                              : colors.onSurface.withAlpha(100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formatDays(alarm.repeatDays),
                            style: textTheme.bodySmall?.copyWith(
                              color: alarm.isEnabled
                                  ? colors.onSurfaceVariant
                                  : colors.onSurface.withAlpha(80),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DifficultyBadge(
                            difficulty: alarm.difficulty,
                            isEnabled: alarm.isEnabled,
                          ),
                        ],
                      ),
                      if (alarm.label.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          alarm.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (bool value) => onToggle(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  final bool isEnabled;

  const _DifficultyBadge({required this.difficulty, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color badgeColor = isEnabled
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final Color textColor = isEnabled
        ? colors.onPrimaryContainer
        : colors.onSurface.withAlpha(80);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(fontSize: 11, color: textColor),
      ),
    );
  }
}
