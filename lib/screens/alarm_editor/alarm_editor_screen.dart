import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import 'widgets/day_selector.dart';
import 'widgets/difficulty_selector.dart';

class AlarmEditorScreen extends ConsumerStatefulWidget {
  final String? alarmId;

  const AlarmEditorScreen({super.key, this.alarmId});

  @override
  ConsumerState<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends ConsumerState<AlarmEditorScreen> {
  late TimeOfDay _time;
  late List<int> _repeatDays;
  late Difficulty _difficulty;
  late TextEditingController _labelController;

  bool get _isEditing => widget.alarmId != null;

  @override
  void initState() {
    super.initState();
    final AlarmModel? existing = widget.alarmId != null
        ? ref
              .read(alarmListProvider)
              .where((AlarmModel a) => a.id == widget.alarmId)
              .firstOrNull
        : null;

    _time = existing?.time ?? TimeOfDay.now();
    _repeatDays = List<int>.from(existing?.repeatDays ?? []);
    _difficulty = existing?.difficulty ?? Difficulty.medium;
    _labelController = TextEditingController(text: existing?.label ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    final AlarmModel alarm = AlarmModel(
      id: widget.alarmId ?? const Uuid().v4(),
      time: _time,
      repeatDays: _repeatDays,
      difficulty: _difficulty,
      label: _labelController.text.trim(),
    );

    if (_isEditing) {
      ref.read(alarmListProvider.notifier).updateAlarm(alarm);
    } else {
      ref.read(alarmListProvider.notifier).addAlarm(alarm);
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'New Alarm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickTime,
              child: Text(
                _time.format(context),
                style: textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text('Change time'),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Repeat',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DaySelector(
            selectedDays: _repeatDays,
            onChanged: (List<int> days) {
              setState(() => _repeatDays = days);
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Difficulty',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DifficultySelector(
            selected: _difficulty,
            onChanged: (Difficulty d) {
              setState(() => _difficulty = d);
            },
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g. Wake up for gym',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
