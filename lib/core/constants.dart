import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum Difficulty {
  easy,
  medium,
  hard;

  double get threshold => switch (this) {
    Difficulty.easy => 0.40,
    Difficulty.medium => 0.60,
    Difficulty.hard => 0.75,
  };

  int? get mercyAttempts => switch (this) {
    Difficulty.easy => 5,
    Difficulty.medium => 10,
    Difficulty.hard => null,
  };

  bool get usesTop3 => this == Difficulty.easy;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };
}

const String modelAssetPath = 'assets/quickdraw_model.tflite';
const String labelsAssetPath = 'assets/labels.txt';
const int modelInputSize = 28;
const int categoryCount = 345;
const double canvasSize = 360.0;
const double mercyReduction = 0.10;
const double canvasStrokeWidth = 4.0;
const double canvasBorderRadius = 16.0;
const Duration idleTimeout = Duration(seconds: 30);
const Duration snoozeDuration = Duration(minutes: 5);

enum AlarmSound {
  defaultTone,
  gentle,
  urgent,
  melody;

  String get assetPath => switch (this) {
    AlarmSound.defaultTone => 'assets/sounds/alarm_default.mp3',
    AlarmSound.gentle => 'assets/sounds/alarm_gentle.mp3',
    AlarmSound.urgent => 'assets/sounds/alarm_urgent.mp3',
    AlarmSound.melody => 'assets/sounds/alarm_melody.mp3',
  };

  String get label => switch (this) {
    AlarmSound.defaultTone => 'Default',
    AlarmSound.gentle => 'Gentle',
    AlarmSound.urgent => 'Urgent',
    AlarmSound.melody => 'Melody',
  };

  String get key => switch (this) {
    AlarmSound.defaultTone => 'default',
    AlarmSound.gentle => 'gentle',
    AlarmSound.urgent => 'urgent',
    AlarmSound.melody => 'melody',
  };

  static AlarmSound fromKey(String key) {
    return AlarmSound.values.firstWhere(
      (AlarmSound s) => s.key == key,
      orElse: () => AlarmSound.defaultTone,
    );
  }
}

final FutureProvider<String> appVersionProvider = FutureProvider<String>((
  Ref<AsyncValue<String>> ref,
) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.version;
});
