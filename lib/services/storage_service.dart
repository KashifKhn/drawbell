import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_model.dart';
import '../models/dismissal_record.dart';

class StorageService {
  static const String _alarmsKey = 'alarms';
  static const String _statsKey = 'dismissal_stats';
  static const String _onboardingKey = 'onboarding_complete';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<AlarmModel> loadAlarms() {
    final String? raw = _prefs?.getString(_alarmsKey);
    if (raw == null) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic e) => AlarmModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final String encoded = jsonEncode(
      alarms.map((AlarmModel a) => a.toJson()).toList(),
    );
    await _prefs?.setString(_alarmsKey, encoded);
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final List<AlarmModel> alarms = loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final List<AlarmModel> alarms = loadAlarms();
    final int index = alarms.indexWhere((AlarmModel a) => a.id == alarm.id);
    if (index != -1) {
      alarms[index] = alarm;
      await saveAlarms(alarms);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final List<AlarmModel> alarms = loadAlarms();
    alarms.removeWhere((AlarmModel a) => a.id == id);
    await saveAlarms(alarms);
  }

  AlarmModel? getAlarm(String id) {
    final List<AlarmModel> alarms = loadAlarms();
    try {
      return alarms.firstWhere((AlarmModel a) => a.id == id);
    } on StateError {
      return null;
    }
  }

  List<DismissalRecord> loadStats() {
    final String? raw = _prefs?.getString(_statsKey);
    if (raw == null) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic e) => DismissalRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDismissal(DismissalRecord record) async {
    final List<DismissalRecord> stats = loadStats();
    stats.add(record);
    final String encoded = jsonEncode(
      stats.map((DismissalRecord r) => r.toJson()).toList(),
    );
    await _prefs?.setString(_statsKey, encoded);
  }

  bool get isOnboardingComplete => _prefs?.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(_onboardingKey, true);
  }
}
