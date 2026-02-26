import 'package:flutter/material.dart';

import '../../../theme.dart';

class PracticeResultOverlay extends StatelessWidget {
  final bool isMatch;
  final String category;
  final double confidence;
  final int attemptCount;
  final int durationSeconds;
  final VoidCallback onPlayAgain;
  final VoidCallback onNewCategory;

  const PracticeResultOverlay({
    super.key,
    required this.isMatch,
    required this.category,
    required this.confidence,
    required this.attemptCount,
    required this.durationSeconds,
    required this.onPlayAgain,
    required this.onNewCategory,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String pct = (confidence * 100).toStringAsFixed(1);

    return Container(
      color: colors.surface.withAlpha(230),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isMatch
                        ? const Color(0xFF4CAF50).withAlpha(30)
                        : AppTheme.brandOrange.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMatch ? Icons.check : Icons.close,
                    size: 32,
                    color: isMatch
                        ? const Color(0xFF4CAF50)
                        : AppTheme.brandOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMatch ? 'Great Job!' : 'Not Quite',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMatch
                      ? 'AI recognized your "$category"'
                      : 'Keep practicing "$category"',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultStat(
                      label: 'Confidence',
                      value: '$pct%',
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    _ResultStat(
                      label: 'Attempts',
                      value: '$attemptCount',
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    _ResultStat(
                      label: 'Time',
                      value: '${durationSeconds}s',
                      colors: colors,
                      textTheme: textTheme,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onNewCategory,
                        child: const Text('New Category'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onPlayAgain,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
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

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.brandOrange,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
