import 'dart:developer' as dev;

import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _audioAvailable = false;

  bool get isPlaying => _isPlaying;

  Future<void> startAlarm() async {
    await WakelockPlus.enable();
    await _loadAudio();
    if (_audioAvailable) {
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(1.0);
      await _player.play();
    }
    _isPlaying = true;
    _startVibration();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setAsset('assets/sounds/alarm_default.mp3');
      _audioAvailable = true;
    } on PlayerException catch (e) {
      dev.log('Asset sound not found: $e');
      _audioAvailable = false;
    } on PlayerInterruptedException catch (e) {
      dev.log('Audio interrupted: $e');
      _audioAvailable = false;
    } catch (e) {
      dev.log('Could not load alarm sound: $e');
      _audioAvailable = false;
    }
  }

  Future<void> stopAlarm() async {
    if (_audioAvailable) {
      await _player.stop();
    }
    _isPlaying = false;
    await Vibration.cancel();
    await WakelockPlus.disable();
  }

  void _startVibration() {
    Vibration.vibrate(pattern: [0, 500, 500, 500], repeat: 0);
  }

  void dispose() {
    _player.dispose();
    Vibration.cancel();
    WakelockPlus.disable();
  }
}
