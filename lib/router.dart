import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';
import 'screens/alarm_editor/alarm_editor_screen.dart';
import 'screens/settings/settings_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/alarm/new',
      builder: (BuildContext context, GoRouterState state) =>
          const AlarmEditorScreen(),
    ),
    GoRoute(
      path: '/alarm/:id/edit',
      builder: (BuildContext context, GoRouterState state) {
        final String alarmId = state.pathParameters['id']!;
        return AlarmEditorScreen(alarmId: alarmId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
  ],
);
