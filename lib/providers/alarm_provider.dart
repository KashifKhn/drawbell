import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_model.dart';
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

  AlarmListNotifier(this._storage) : super([]);

  void loadAlarms() {
    state = _storage.loadAlarms();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    await _storage.addAlarm(alarm);
    state = _storage.loadAlarms();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    await _storage.updateAlarm(alarm);
    state = _storage.loadAlarms();
  }

  Future<void> deleteAlarm(String id) async {
    await _storage.deleteAlarm(id);
    state = _storage.loadAlarms();
  }

  Future<void> toggleAlarm(String id) async {
    final AlarmModel? alarm = _storage.getAlarm(id);
    if (alarm != null) {
      await _storage.updateAlarm(alarm.copyWith(isEnabled: !alarm.isEnabled));
      state = _storage.loadAlarms();
    }
  }
}
