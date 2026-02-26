import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dismissal_record.dart';
import '../../providers/alarm_provider.dart';

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
        appBar: AppBar(title: const Text('Stats')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            colors: colors,
            children: [
              _StatRow(
                label: 'Total dismissals',
                value: '$totalDismissals',
                textTheme: textTheme,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Average attempts',
                value: avgAttempts.toStringAsFixed(1),
                textTheme: textTheme,
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'First-try successes',
                value: '$firstTryCount',
                textTheme: textTheme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hardest.isNotEmpty) ...[
            _SectionTitle(
              title: 'Hardest categories',
              textTheme: textTheme,
              colors: colors,
            ),
            const SizedBox(height: 8),
            _StatCard(
              colors: colors,
              children: [
                for (int i = 0; i < hardest.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  _StatRow(
                    label: hardest[i].key,
                    value:
                        '${hardest[i].value.toStringAsFixed(1)} avg attempts',
                    textTheme: textTheme,
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (easiest.isNotEmpty) ...[
            _SectionTitle(
              title: 'Easiest categories',
              textTheme: textTheme,
              colors: colors,
            ),
            const SizedBox(height: 8),
            _StatCard(
              colors: colors,
              children: [
                for (int i = 0; i < easiest.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  _StatRow(
                    label: easiest[i].key,
                    value:
                        '${easiest[i].value.toStringAsFixed(1)} avg attempts',
                    textTheme: textTheme,
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final TextTheme textTheme;
  final ColorScheme colors;

  const _SectionTitle({
    required this.title,
    required this.textTheme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ColorScheme colors;
  final List<Widget> children;

  const _StatCard({required this.colors, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;

  const _StatRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: textTheme.bodyMedium)),
        const SizedBox(width: 16),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
