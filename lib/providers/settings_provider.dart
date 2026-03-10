import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../services/storage_service.dart';
import 'alarm_provider.dart';

class AppSettings {
  final Difficulty defaultDifficulty;
  final int snoozeMinutes;
  final ThemeMode themeMode;
  final bool vibrationEnabled;
  final String defaultSoundKey;
  final bool defaultSnoozeEnabled;

  const AppSettings({
    required this.defaultDifficulty,
    required this.snoozeMinutes,
    required this.themeMode,
    required this.vibrationEnabled,
    required this.defaultSoundKey,
    required this.defaultSnoozeEnabled,
  });

  AppSettings copyWith({
    Difficulty? defaultDifficulty,
    int? snoozeMinutes,
    ThemeMode? themeMode,
    bool? vibrationEnabled,
    String? defaultSoundKey,
    bool? defaultSnoozeEnabled,
  }) {
    return AppSettings(
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      themeMode: themeMode ?? this.themeMode,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultSoundKey: defaultSoundKey ?? this.defaultSoundKey,
      defaultSnoozeEnabled: defaultSnoozeEnabled ?? this.defaultSnoozeEnabled,
    );
  }
}

final StateNotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((Ref ref) {
      final StorageService storage = ref.watch(storageServiceProvider);
      return SettingsNotifier(storage);
    });

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage)
    : super(
        AppSettings(
          defaultDifficulty: Difficulty.values[_storage.defaultDifficultyIndex],
          snoozeMinutes: _storage.snoozeMinutes,
          themeMode: _storage.themeMode,
          vibrationEnabled: _storage.vibrationEnabled,
          defaultSoundKey: _storage.defaultSoundKey,
          defaultSnoozeEnabled: _storage.defaultSnoozeEnabled,
        ),
      );

  Future<void> setDefaultDifficulty(Difficulty difficulty) async {
    await _storage.setDefaultDifficultyIndex(difficulty.index);
    state = state.copyWith(defaultDifficulty: difficulty);
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    await _storage.setSnoozeMinutes(minutes);
    state = state.copyWith(snoozeMinutes: minutes);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _storage.setVibrationEnabled(value);
    state = state.copyWith(vibrationEnabled: value);
  }

  Future<void> setDefaultSoundKey(String key) async {
    await _storage.setDefaultSoundKey(key);
    state = state.copyWith(defaultSoundKey: key);
  }

  Future<void> setDefaultSnoozeEnabled(bool value) async {
    await _storage.setDefaultSnoozeEnabled(value);
    state = state.copyWith(defaultSnoozeEnabled: value);
  }
}
