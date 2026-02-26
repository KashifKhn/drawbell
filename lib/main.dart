import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/alarm_provider.dart';
import 'router.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const DrawBellApp(),
    ),
  );
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
    Future.microtask(() => ref.read(alarmListProvider.notifier).loadAlarms());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DrawBell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
