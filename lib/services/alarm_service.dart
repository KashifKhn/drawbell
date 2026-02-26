import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  final NotificationService _notifications = NotificationService();

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;

    final DateTime nextFire = computeNextFireTime(alarm.time, alarm.repeatDays);
    final String payload = jsonEncode({
      'alarmId': alarm.id,
      'difficulty': alarm.difficulty.index,
      'categories': alarm.categories,
      'sound': alarm.sound,
    });

    final String title = alarm.label.isNotEmpty ? alarm.label : 'DrawBell';
    final String body =
        'Alarm at ${_formatTime(alarm.time)} — draw to dismiss!';

    await _notifications.scheduleAlarm(
      id: _notificationId(alarm.id),
      title: title,
      body: body,
      scheduledTime: nextFire,
      payload: payload,
    );
  }

  Future<void> cancelAlarm(String alarmId) async {
    await _notifications.cancelAlarm(_notificationId(alarmId));
  }

  Future<void> rescheduleAll(List<AlarmModel> alarms) async {
    await _notifications.cancelAll();
    for (final AlarmModel alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  static DateTime computeNextFireTime(TimeOfDay time, List<int> repeatDays) {
    final DateTime now = DateTime.now();
    final DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (repeatDays.isEmpty) {
      if (candidate.isAfter(now)) return candidate;
      return candidate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 8; i++) {
      final DateTime check = candidate.add(Duration(days: i));
      final int appDay = (check.weekday - 1) % 7;
      if (repeatDays.contains(appDay)) {
        if (i == 0 && !check.isAfter(now)) continue;
        return DateTime(
          check.year,
          check.month,
          check.day,
          time.hour,
          time.minute,
        );
      }
    }

    return candidate.add(const Duration(days: 1));
  }

  int _notificationId(String alarmId) {
    return alarmId.hashCode & 0x7FFFFFFF;
  }

  String _formatTime(TimeOfDay time) {
    final String hour = time.hourOfPeriod == 0 ? '12' : '${time.hourOfPeriod}';
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
