import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'screens/alarm_editor/alarm_editor_screen.dart';
import 'screens/alarm_ring/alarm_ring_screen.dart';
import 'screens/app_shell.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/practice/practice_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/stats/stats_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: '/alarm/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmEditorScreen(),
      ),
      GoRoute(
        path: '/alarm/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final String alarmId = state.pathParameters['id']!;
          return AlarmEditorScreen(alarmId: alarmId);
        },
      ),
      GoRoute(
        path: '/alarm/ring',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic> extras =
              state.extra as Map<String, dynamic>? ?? const {};
          final Difficulty difficulty =
              extras['difficulty'] as Difficulty? ?? Difficulty.medium;
          final List<String> categories =
              extras['categories'] as List<String>? ?? const [];
          final String sound = extras['sound'] as String? ?? 'default';
          final bool isTestMode = extras['isTestMode'] as bool? ?? false;
          final String? alarmId = extras['alarmId'] as String?;
          return AlarmRingScreen(
            difficulty: difficulty,
            categories: categories,
            sound: sound,
            isTestMode: isTestMode,
            alarmId: alarmId,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) {
              return AppShell(
                currentIndex: shell.currentIndex,
                onTabChanged: (int index) {
                  if (index == -1) {
                    context.push('/alarm/new');
                    return;
                  }
                  shell.goBranch(index);
                },
                child: shell,
              );
            },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (BuildContext context, GoRouterState state) =>
                    const PracticeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (BuildContext context, GoRouterState state) =>
                    const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
