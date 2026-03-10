import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'native_alarm_service.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const String _defaultAlarmChannelId = 'drawbell_alarm_v3_default';
const String _alarmChannelName = 'DrawBell Alarms';
const String _alarmChannelDescription = 'Alarm notifications for DrawBell';

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
  final NativeAlarmService _nativeAlarms = NativeAlarmService();

  Future<void> init({void Function(String payload)? onTap}) async {
    if (_initialized) return;
    _onNotificationTap = onTap;
    await _nativeAlarms.init(onAlarmLaunch: onTap);

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
      _defaultAlarmChannelId,
      _alarmChannelName,
      description: _alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
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
    required String sound,
  }) async {
    await _nativeAlarms.scheduleAlarm(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
      sound: sound,
    );

    if (Platform.isAndroid) {
      dev.log('Scheduled native alarm $id at $scheduledTime');
      return;
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final AndroidNotificationSound? androidSound = _soundFor(sound);
    final String channelId = _channelIdForSound(sound);

    await _createSoundChannel(channelId: channelId, sound: androidSound);

    final AndroidNotificationDetails android = AndroidNotificationDetails(
      channelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 400, 600]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: androidSound,
      ongoing: true,
      autoCancel: false,
    );

    final NotificationDetails details = NotificationDetails(android: android);

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

  Future<void> _createSoundChannel({
    required String channelId,
    required AndroidNotificationSound? sound,
  }) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      _alarmChannelName,
      description: _alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: sound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  AndroidNotificationSound? _soundFor(String sound) {
    if (sound.startsWith('content://') || sound.startsWith('file://')) {
      return UriAndroidNotificationSound(sound);
    }
    return null;
  }

  String _channelIdForSound(String sound) {
    if (sound.startsWith('content://') || sound.startsWith('file://')) {
      final int hash = _stableHash(sound);
      return 'drawbell_alarm_v3_$hash';
    }
    return _defaultAlarmChannelId;
  }

  int _stableHash(String input) {
    int hash = 2166136261;
    for (final int codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    return hash;
  }

  Future<void> cancelAlarm(int id) async {
    await _nativeAlarms.cancelAlarm(id);
    await _plugin.cancel(id: id);
    dev.log('Cancelled alarm $id');
  }

  Future<void> cancelAll() async {
    await _nativeAlarms.cancelAll();
    await _plugin.cancelAll();
  }

  Future<void> stopRingingAlarm() async {
    await _nativeAlarms.stopRingingAlarm();
  }

  Future<String?> consumeInitialAlarmPayload() async {
    return _nativeAlarms.consumeLaunchPayload();
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;

    final bool? notifGranted = await android.requestNotificationsPermission();
    final bool? exactGranted = await android.requestExactAlarmsPermission();

    return (notifGranted ?? false) && (exactGranted ?? false);
  }
}
