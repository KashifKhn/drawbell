import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'providers/alarm_provider.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

late final GoRouter _router;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storage = StorageService();
  await storage.init();

  final String initialRoute = storage.isOnboardingComplete
      ? '/'
      : '/onboarding';
  _router = buildRouter(initialLocation: initialRoute);

  final NotificationService notifications = NotificationService();
  await notifications.init(
    onTap: (String payload) {
      _handleNotificationPayload(payload);
    },
  );
  await notifications.requestPermissions();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const DrawBellApp(),
    ),
  );
}

void _handleNotificationPayload(String payload) {
  if (payload.isEmpty) return;
  try {
    final Map<String, dynamic> data =
        jsonDecode(payload) as Map<String, dynamic>;
    final int difficultyIndex = data['difficulty'] as int? ?? 1;
    final Difficulty difficulty = Difficulty.values[difficultyIndex];
    final List<String> categories = data['categories'] != null
        ? List<String>.from(data['categories'] as List)
        : const [];
    final String sound = data['sound'] as String? ?? 'default';
    final String? alarmId = data['alarmId'] as String?;
    _router.push(
      '/alarm/ring',
      extra: {
        'difficulty': difficulty,
        'categories': categories,
        'sound': sound,
        if (alarmId != null) 'alarmId': alarmId,
      },
    );
  } on FormatException {
    _router.push('/alarm/ring', extra: {'difficulty': Difficulty.medium});
  }
}

class DrawBellApp extends ConsumerStatefulWidget {
  const DrawBellApp({super.key});

  @override
  ConsumerState<DrawBellApp> createState() => _DrawBellAppState();
}

class _DrawBellAppState extends ConsumerState<DrawBellApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alarmListProvider.notifier).loadAlarms();
      ref.read(dismissalStatsProvider.notifier).loadStats();
      ref.read(alarmListProvider.notifier).rescheduleAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DrawBell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
