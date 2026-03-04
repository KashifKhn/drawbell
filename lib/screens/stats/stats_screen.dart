import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dismissal_record.dart';
import '../../providers/alarm_provider.dart';
import 'widgets/accuracy_card.dart';
import 'widgets/category_section.dart';
import 'widgets/consistency_chart.dart';
import 'widgets/gamification_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/summary_row.dart';
import 'widgets/wake_up_time_card.dart';
import 'widgets/week_day_selector.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DismissalRecord> stats = ref.watch(dismissalStatsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (stats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Morning Stats')),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.read(dismissalStatsProvider.notifier).loadStats();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
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
              ),
            ],
          ),
        ),
      );
    }

    final List<DismissalRecord> lastWeek = stats
        .where(
          (DismissalRecord r) => r.timestamp.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
        .toList();

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
      appBar: AppBar(title: const Text('Morning Stats')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dismissalStatsProvider.notifier).loadStats();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            const WeekDaySelector(),
            const SizedBox(height: 20),
            SummaryRow(allStats: stats, lastWeekStats: lastWeek),
            const SizedBox(height: 16),
            StreakCard(allStats: stats),
            const SizedBox(height: 16),
            AccuracyCard(allStats: stats),
            const SizedBox(height: 16),
            WakeUpTimeCard(weekStats: lastWeek),
            const SizedBox(height: 16),
            ConsistencyChart(weekStats: lastWeek),
            const SizedBox(height: 16),
            if (hardest.isNotEmpty) ...[
              CategorySection(
                title: 'Hardest Categories',
                entries: hardest,
                isHardest: true,
              ),
              const SizedBox(height: 16),
            ],
            if (easiest.isNotEmpty)
              CategorySection(
                title: 'Easiest Categories',
                entries: easiest,
                isHardest: false,
              ),
            const SizedBox(height: 16),
            GamificationCard(allStats: stats),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
