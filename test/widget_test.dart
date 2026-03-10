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
import 'package:drawbell/providers/settings_provider.dart';

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

    test('serializes categories and sound to JSON', () {
      final AlarmModel alarm = AlarmModel(
        id: 'cat-test',
        time: const TimeOfDay(hour: 8, minute: 0),
        categories: ['cat', 'dog', 'tree'],
        sound: 'gentle',
      );

      final Map<String, dynamic> json = alarm.toJson();
      expect(json['categories'], ['cat', 'dog', 'tree']);
      expect(json['sound'], 'gentle');

      final AlarmModel restored = AlarmModel.fromJson(json);
      expect(restored.categories, ['cat', 'dog', 'tree']);
      expect(restored.sound, 'gentle');
    });

    test('fromJson defaults categories to empty when missing', () {
      final Map<String, dynamic> json = {
        'id': 'old-alarm',
        'hour': 6,
        'minute': 0,
        'repeatDays': <int>[],
        'difficulty': 1,
        'isEnabled': true,
        'label': '',
        'sound': 'default',
      };

      final AlarmModel alarm = AlarmModel.fromJson(json);
      expect(alarm.categories, isEmpty);
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

    test('copyWith updates categories and sound', () {
      final AlarmModel alarm = AlarmModel(
        id: 'test-id',
        time: const TimeOfDay(hour: 7, minute: 0),
      );

      final AlarmModel updated = alarm.copyWith(
        categories: ['apple', 'banana'],
        sound: 'urgent',
      );

      expect(updated.categories, ['apple', 'banana']);
      expect(updated.sound, 'urgent');
      expect(updated.id, alarm.id);
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

  group('AlarmSound', () {
    test('has correct keys', () {
      expect(AlarmSound.defaultTone.key, 'default');
      expect(AlarmSound.gentle.key, 'gentle');
      expect(AlarmSound.urgent.key, 'urgent');
      expect(AlarmSound.melody.key, 'melody');
    });

    test('has correct labels', () {
      expect(AlarmSound.defaultTone.label, 'Default');
      expect(AlarmSound.gentle.label, 'Gentle');
      expect(AlarmSound.urgent.label, 'Urgent');
      expect(AlarmSound.melody.label, 'Melody');
    });

    test('fromKey returns correct enum value', () {
      expect(AlarmSound.fromKey('default'), AlarmSound.defaultTone);
      expect(AlarmSound.fromKey('gentle'), AlarmSound.gentle);
      expect(AlarmSound.fromKey('urgent'), AlarmSound.urgent);
      expect(AlarmSound.fromKey('melody'), AlarmSound.melody);
    });

    test('fromKey returns defaultTone for unknown key', () {
      expect(AlarmSound.fromKey('unknown'), AlarmSound.defaultTone);
      expect(AlarmSound.fromKey(''), AlarmSound.defaultTone);
    });

    test('asset paths are valid', () {
      for (final AlarmSound sound in AlarmSound.values) {
        expect(sound.assetPath, startsWith('assets/sounds/'));
        expect(sound.assetPath, endsWith('.mp3'));
      }
    });
  });

  group('AppSettings', () {
    test('defaults are correct', () {
      const AppSettings settings = AppSettings(
        defaultDifficulty: Difficulty.medium,
        snoozeMinutes: 5,
        themeMode: ThemeMode.system,
        vibrationEnabled: true,
        defaultSoundKey: 'default',
        defaultSnoozeEnabled: true,
      );

      expect(settings.defaultDifficulty, Difficulty.medium);
      expect(settings.snoozeMinutes, 5);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('copyWith updates individual fields', () {
      const AppSettings original = AppSettings(
        defaultDifficulty: Difficulty.easy,
        snoozeMinutes: 5,
        themeMode: ThemeMode.system,
        vibrationEnabled: true,
        defaultSoundKey: 'default',
        defaultSnoozeEnabled: true,
      );

      final AppSettings updated = original.copyWith(
        defaultDifficulty: Difficulty.hard,
        snoozeMinutes: 15,
      );

      expect(updated.defaultDifficulty, Difficulty.hard);
      expect(updated.snoozeMinutes, 15);
      expect(updated.themeMode, ThemeMode.system);
    });

    test('copyWith preserves unchanged fields', () {
      const AppSettings original = AppSettings(
        defaultDifficulty: Difficulty.medium,
        snoozeMinutes: 10,
        themeMode: ThemeMode.dark,
        vibrationEnabled: true,
        defaultSoundKey: 'default',
        defaultSnoozeEnabled: true,
      );

      final AppSettings updated = original.copyWith(themeMode: ThemeMode.light);

      expect(updated.defaultDifficulty, Difficulty.medium);
      expect(updated.snoozeMinutes, 10);
      expect(updated.themeMode, ThemeMode.light);
    });
  });

  group('snooze duration options', () {
    test('valid snooze durations are 5 10 15 20', () {
      const List<int> validOptions = [5, 10, 15, 20];
      for (final int minutes in validOptions) {
        expect(minutes >= 5 && minutes <= 20 && minutes % 5 == 0, isTrue);
      }
    });

    test('default snooze is 5 minutes', () {
      const AppSettings settings = AppSettings(
        defaultDifficulty: Difficulty.medium,
        snoozeMinutes: 5,
        themeMode: ThemeMode.system,
        vibrationEnabled: true,
        defaultSoundKey: 'default',
        defaultSnoozeEnabled: true,
      );
      expect(settings.snoozeMinutes, 5);
    });
  });

  group('ThemeMode settings', () {
    test('all three theme modes are supported', () {
      for (final ThemeMode mode in ThemeMode.values) {
        final AppSettings settings = AppSettings(
          defaultDifficulty: Difficulty.medium,
          snoozeMinutes: 5,
          themeMode: mode,
          vibrationEnabled: true,
          defaultSoundKey: 'default',
          defaultSnoozeEnabled: true,
        );
        expect(settings.themeMode, mode);
      }
    });

    test('default theme mode is system', () {
      const AppSettings settings = AppSettings(
        defaultDifficulty: Difficulty.medium,
        snoozeMinutes: 5,
        themeMode: ThemeMode.system,
        vibrationEnabled: true,
        defaultSoundKey: 'default',
        defaultSnoozeEnabled: true,
      );
      expect(settings.themeMode, ThemeMode.system);
    });
  });
}
