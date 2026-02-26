import 'dart:developer' as dev;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

void Function(String payload)? _onNotificationTap;

void _handleNotificationResponse(NotificationResponse response) {
  final String payload = response.payload ?? '';
  _onNotificationTap?.call(payload);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  Future<void> init({void Function(String payload)? onTap}) async {
    if (_initialized) return;
    _onNotificationTap = onTap;

    tz.initializeTimeZones();
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _createChannel();
    _initialized = true;
  }

  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'drawbell_alarm',
      'DrawBell Alarms',
      description: 'Alarm notifications for DrawBell',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'drawbell_alarm',
      'DrawBell Alarms',
      channelDescription: 'Alarm notifications for DrawBell',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails details = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tzTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );

    dev.log('Scheduled alarm $id at $scheduledTime');
  }

  Future<void> cancelAlarm(int id) async {
    await _plugin.cancel(id: id);
    dev.log('Cancelled alarm $id');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
