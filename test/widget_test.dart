import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drawbell/screens/home/home_screen.dart';
import 'package:drawbell/screens/home/widgets/empty_state.dart';
import 'package:drawbell/core/constants.dart';
import 'package:drawbell/models/alarm_model.dart';
import 'package:drawbell/core/utils.dart';
import 'package:drawbell/services/alarm_service.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar with title', (WidgetTester tester) async {
      final GoRouter testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DrawBell'), findsOneWidget);
    });

    testWidgets('shows empty state when no alarms', (
      WidgetTester tester,
    ) async {
      final GoRouter testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No alarms yet'), findsOneWidget);
    });
  });

  group('Difficulty', () {
    test('has correct thresholds', () {
      expect(Difficulty.easy.threshold, 0.40);
      expect(Difficulty.medium.threshold, 0.60);
      expect(Difficulty.hard.threshold, 0.75);
    });

    test('has correct mercy attempts', () {
      expect(Difficulty.easy.mercyAttempts, 5);
      expect(Difficulty.medium.mercyAttempts, 10);
      expect(Difficulty.hard.mercyAttempts, isNull);
    });

    test('only easy uses top-3 matching', () {
      expect(Difficulty.easy.usesTop3, isTrue);
      expect(Difficulty.medium.usesTop3, isFalse);
      expect(Difficulty.hard.usesTop3, isFalse);
    });

    test('has correct labels', () {
      expect(Difficulty.easy.label, 'Easy');
      expect(Difficulty.medium.label, 'Medium');
      expect(Difficulty.hard.label, 'Hard');
    });
  });

  group('AlarmModel', () {
    test('serializes to and from JSON', () {
      final AlarmModel alarm = AlarmModel(
        id: 'test-id',
        time: const TimeOfDay(hour: 7, minute: 30),
        repeatDays: [0, 1, 2, 3, 4],
        difficulty: Difficulty.medium,
        isEnabled: true,
        label: 'Work alarm',
      );

      final Map<String, dynamic> json = alarm.toJson();
      final AlarmModel restored = AlarmModel.fromJson(json);

      expect(restored.id, alarm.id);
      expect(restored.time.hour, 7);
      expect(restored.time.minute, 30);
      expect(restored.repeatDays, [0, 1, 2, 3, 4]);
      expect(restored.difficulty, Difficulty.medium);
      expect(restored.isEnabled, isTrue);
      expect(restored.label, 'Work alarm');
    });

    test('copyWith creates modified copy', () {
      final AlarmModel alarm = AlarmModel(
        id: 'test-id',
        time: const TimeOfDay(hour: 7, minute: 30),
      );

      final AlarmModel toggled = alarm.copyWith(isEnabled: false);

      expect(toggled.isEnabled, isFalse);
      expect(toggled.id, alarm.id);
      expect(toggled.time, alarm.time);
    });
  });

  group('formatDays', () {
    test('empty list returns Once', () {
      expect(formatDays([]), 'Once');
    });

    test('all 7 days returns Every day', () {
      expect(formatDays([0, 1, 2, 3, 4, 5, 6]), 'Every day');
    });

    test('Mon-Fri returns Weekdays', () {
      expect(formatDays([0, 1, 2, 3, 4]), 'Weekdays');
    });

    test('Sat-Sun returns Weekend', () {
      expect(formatDays([5, 6]), 'Weekend');
    });

    test('specific days are listed', () {
      expect(formatDays([0, 2, 4]), 'Mon, Wed, Fri');
    });
  });

  group('AlarmService.computeNextFireTime', () {
    test('returns today if alarm time is in the future', () {
      final TimeOfDay futureTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 2) % 24,
        minute: 0,
      );

      final DateTime next = AlarmService.computeNextFireTime(futureTime, []);

      expect(next.isAfter(DateTime.now()), isTrue);
    });

    test('returns tomorrow if alarm time has passed today', () {
      final TimeOfDay pastTime = TimeOfDay(
        hour: (TimeOfDay.now().hour - 2 + 24) % 24,
        minute: 0,
      );

      final DateTime next = AlarmService.computeNextFireTime(pastTime, []);
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(next.day, tomorrow.day);
    });
  });
}
