import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'screens/alarm_editor/alarm_editor_screen.dart';
import 'screens/alarm_ring/alarm_ring_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/stats/stats_screen.dart';

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
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
        path: '/alarm/ring',
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic> extras =
              state.extra as Map<String, dynamic>? ?? const {};
          final Difficulty difficulty =
              extras['difficulty'] as Difficulty? ?? Difficulty.medium;
          final List<String> categories =
              extras['categories'] as List<String>? ?? const [];
          return AlarmRingScreen(
            difficulty: difficulty,
            categories: categories,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (BuildContext context, GoRouterState state) =>
            const StatsScreen(),
      ),
    ],
  );
}
