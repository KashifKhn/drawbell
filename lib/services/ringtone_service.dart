import 'package:flutter/services.dart';

class RingtoneInfo {
  final String title;
  final String uri;

  const RingtoneInfo({required this.title, required this.uri});
}

class RingtoneService {
  static const MethodChannel _channel = MethodChannel(
    'dev.kashifkhan.drawbell/ringtones',
  );

  static Future<List<RingtoneInfo>> getAlarmRingtones() async {
    try {
      final List<Object?> result =
          await _channel.invokeListMethod('getAlarmRingtones') ?? [];
      return result
          .map((Object? e) {
            final Map<String, String> m = Map<String, String>.from(e as Map);
            return RingtoneInfo(
              title: m['title'] ?? 'Unknown',
              uri: m['uri'] ?? '',
            );
          })
          .where((RingtoneInfo r) => r.uri.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String> requestAudioPermission() async {
    try {
      final String result =
          await _channel.invokeMethod<String>('requestAudioPermission') ??
          'denied';
      return result;
    } catch (_) {
      return 'denied';
    }
  }

  static Future<bool> openAppSettings() async {
    try {
      final bool result =
          await _channel.invokeMethod<bool>('openAppSettings') ?? false;
      return result;
    } catch (_) {
      return false;
    }
  }
}
