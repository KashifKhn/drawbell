import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../services/alarm_service.dart';

String formatTimeOfDay(TimeOfDay time) {
  final DateTime now = DateTime.now();
  final DateTime dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  return DateFormat.jm().format(dateTime);
}

String formatDays(List<int> days) {
  if (days.isEmpty) return 'Once';
  if (days.length == 7) return 'Every day';

  const List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final bool isWeekdays = days.length == 5 && days.every((int d) => d < 5);
  if (isWeekdays) return 'Weekdays';

  final bool isWeekend =
      days.length == 2 && days.contains(5) && days.contains(6);
  if (isWeekend) return 'Weekend';

  return days.map((int d) => weekdays[d]).join(', ');
}

String formatTimeUntilAlarm(TimeOfDay time, List<int> repeatDays) {
  final DateTime nextFire = AlarmService.computeNextFireTime(time, repeatDays);
  final Duration diff = nextFire.difference(DateTime.now());

  final int hours = diff.inHours;
  final int minutes = diff.inMinutes % 60;

  if (hours == 0 && minutes == 0) return 'Alarm set for less than a minute';
  if (hours == 0) return 'Alarm set for $minutes min from now';
  if (minutes == 0) return 'Alarm set for $hours hr from now';
  return 'Alarm set for $hours hr $minutes min from now';
}
