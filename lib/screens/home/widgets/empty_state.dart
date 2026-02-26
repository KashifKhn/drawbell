import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_add_rounded,
              size: 80,
              color: colors.onSurface.withAlpha(60),
            ),
            const SizedBox(height: 16),
            Text(
              'No alarms yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first alarm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
