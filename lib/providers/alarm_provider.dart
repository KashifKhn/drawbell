import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';

final Provider<StorageService> storageServiceProvider =
    Provider<StorageService>((Ref ref) {
      return StorageService();
    });

final StateNotifierProvider<AlarmListNotifier, List<AlarmModel>>
alarmListProvider = StateNotifierProvider<AlarmListNotifier, List<AlarmModel>>((
  Ref ref,
) {
  final StorageService storage = ref.watch(storageServiceProvider);
  return AlarmListNotifier(storage);
});

class AlarmListNotifier extends StateNotifier<List<AlarmModel>> {
  final StorageService _storage;
  final AlarmService _alarmService = AlarmService();

  AlarmListNotifier(this._storage) : super([]);

  void loadAlarms() {
    state = _storage.loadAlarms();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    await _storage.addAlarm(alarm);
    state = _storage.loadAlarms();
    await _alarmService.scheduleAlarm(alarm);
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    await _storage.updateAlarm(alarm);
    state = _storage.loadAlarms();
    if (alarm.isEnabled) {
      await _alarmService.scheduleAlarm(alarm);
    } else {
      await _alarmService.cancelAlarm(alarm.id);
    }
  }

  Future<void> deleteAlarm(String id) async {
    await _alarmService.cancelAlarm(id);
    await _storage.deleteAlarm(id);
    state = _storage.loadAlarms();
  }

  Future<void> toggleAlarm(String id) async {
    final AlarmModel? alarm = _storage.getAlarm(id);
    if (alarm != null) {
      final AlarmModel toggled = alarm.copyWith(isEnabled: !alarm.isEnabled);
      await _storage.updateAlarm(toggled);
      state = _storage.loadAlarms();
      if (toggled.isEnabled) {
        await _alarmService.scheduleAlarm(toggled);
      } else {
        await _alarmService.cancelAlarm(toggled.id);
      }
    }
  }

  Future<void> rescheduleAll() async {
    await _alarmService.rescheduleAll(state);
  }
}
