import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import 'widgets/alarm_card.dart';
import 'widgets/empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<AlarmModel> alarms = ref.watch(alarmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DrawBell'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: alarms.isEmpty
          ? const EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alarms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final AlarmModel alarm = alarms[index];
                return AlarmCard(
                  alarm: alarm,
                  onToggle: (_) {
                    ref.read(alarmListProvider.notifier).toggleAlarm(alarm.id);
                  },
                  onTap: () => context.push('/alarm/${alarm.id}/edit'),
                  onDismissed: () {
                    ref.read(alarmListProvider.notifier).deleteAlarm(alarm.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alarm deleted')),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/alarm/new'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
