import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import 'widgets/alarm_card.dart';
import 'widgets/empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<AlarmModel> alarms = ref.watch(alarmListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DrawBell',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'Wake up creatively',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                onSelected: (String value) {
                  if (value == 'settings') {
                    context.go('/settings');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
          if (alarms.isEmpty)
            const SliverFillRemaining(child: EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: alarms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final AlarmModel alarm = alarms[index];
                  return AlarmCard(
                    alarm: alarm,
                    onToggle: (_) {
                      ref
                          .read(alarmListProvider.notifier)
                          .toggleAlarm(alarm.id);
                      final bool willEnable = !alarm.isEnabled;
                      final String message = willEnable
                          ? formatTimeUntilAlarm(alarm.time, alarm.repeatDays)
                          : 'Alarm off';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onTap: () => context.push('/alarm/${alarm.id}/edit'),
                    onDismissed: () {
                      ref
                          .read(alarmListProvider.notifier)
                          .deleteAlarm(alarm.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm deleted')),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
