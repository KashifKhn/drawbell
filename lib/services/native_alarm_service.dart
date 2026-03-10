import 'dart:io';

import 'package:flutter/services.dart';

class NativeAlarmService {
  static final NativeAlarmService _instance = NativeAlarmService._();
  factory NativeAlarmService() => _instance;
  NativeAlarmService._();

  static const MethodChannel _channel = MethodChannel(
    'dev.kashifkhan.drawbell/native_alarm',
  );

  bool _initialized = false;
  void Function(String payload)? _onAlarmLaunch;

  Future<void> init({void Function(String payload)? onAlarmLaunch}) async {
    _onAlarmLaunch = onAlarmLaunch;
    if (!Platform.isAndroid || _initialized) {
      return;
    }

    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onAlarmLaunch') {
        final String payload = call.arguments as String? ?? '';
        if (payload.isNotEmpty) {
          _onAlarmLaunch?.call(payload);
        }
      }
    });
    _initialized = true;
  }

  Future<String?> consumeLaunchPayload() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final String? payload = await _channel.invokeMethod<String>(
      'consumeLaunchPayload',
    );
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return payload;
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String sound,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('scheduleAlarm', {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
      'payload': payload,
      'sound': sound,
    });
  }

  Future<void> cancelAlarm(int id) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('cancelAlarm', {'id': id});
  }

  Future<void> cancelAll() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('cancelAll');
  }

  Future<void> stopRingingAlarm() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('stopRingingAlarm');
  }
}
