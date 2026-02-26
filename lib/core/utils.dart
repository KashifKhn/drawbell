import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

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
