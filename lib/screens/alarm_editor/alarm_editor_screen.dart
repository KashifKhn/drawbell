import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../../services/classifier_service.dart';
import '../../theme.dart';
import 'widgets/category_picker.dart';
import 'widgets/day_selector.dart';
import 'widgets/sound_picker.dart';

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
  late List<String> _categories;
  late String _sound;
  late bool _snooze;
  List<String> _allLabels = [];

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
    _categories = List<String>.from(existing?.categories ?? []);
    _sound = existing?.sound ?? 'default';
    _snooze = existing?.snooze ?? true;
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final List<String> labels = await ClassifierService.loadLabels();
    if (mounted) setState(() => _allLabels = labels);
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

  Future<void> _openCategoryPicker() async {
    if (_allLabels.isEmpty) return;
    final List<String>? result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute<List<String>>(
        builder: (_) =>
            CategoryPicker(allCategories: _allLabels, selected: _categories),
      ),
    );
    if (result != null && mounted) {
      setState(() => _categories = result);
    }
  }

  void _save() {
    final AlarmModel alarm = AlarmModel(
      id: widget.alarmId ?? const Uuid().v4(),
      time: _time,
      repeatDays: _repeatDays,
      difficulty: _difficulty,
      label: _labelController.text.trim(),
      categories: _categories,
      sound: _sound,
      snooze: _snooze,
    );

    if (_isEditing) {
      ref.read(alarmListProvider.notifier).updateAlarm(alarm);
    } else {
      ref.read(alarmListProvider.notifier).addAlarm(alarm);
    }

    final String message = formatTimeUntilAlarm(_time, _repeatDays);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    context.pop();
  }

  Future<void> _deleteAlarm() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: const Text('Are you sure you want to delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(alarmListProvider.notifier).deleteAlarm(widget.alarmId!);
      if (mounted) context.pop();
    }
  }

  void _testChallenge() {
    context.push(
      '/alarm/ring',
      extra: {
        'difficulty': _difficulty,
        'categories': _categories,
        'sound': _sound,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'New Alarm'),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.brandOrange, fontSize: 14),
          ),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.brandOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildTimePicker(colors, textTheme),
          const SizedBox(height: 8),
          Center(
            child: Text(
              formatTimeUntilAlarm(_time, _repeatDays),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildRepeatSection(colors, textTheme),
          const SizedBox(height: 16),
          _buildSettingsCard(colors, textTheme),
          const SizedBox(height: 16),
          _buildDismissalChallenge(colors, textTheme),
          const SizedBox(height: 16),
          _buildTestButton(),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            _buildDeleteButton(colors),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimePicker(ColorScheme colors, TextTheme textTheme) {
    final String hour = _time.hourOfPeriod == 0
        ? '12'
        : _time.hourOfPeriod.toString().padLeft(2, '0');
    final String minute = _time.minute.toString().padLeft(2, '0');
    final String period = _time.period == DayPeriod.am ? 'AM' : 'PM';

    return GestureDetector(
      onTap: _pickTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TimeBox(value: hour, colors: colors, textTheme: textTheme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  fontSize: 36,
                ),
              ),
            ),
            _TimeBox(value: minute, colors: colors, textTheme: textTheme),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Repeat',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DaySelector(
          selectedDays: _repeatDays,
          onChanged: (List<int> days) => setState(() => _repeatDays = days),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(ColorScheme colors, TextTheme textTheme) {
    final String labelValue = _labelController.text.isEmpty
        ? 'None'
        : _labelController.text;
    final String soundValue = AlarmSound.fromKey(_sound).label;

    return Card(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.label_outline,
            title: 'Label',
            trailing: Text(
              labelValue,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            showChevron: true,
            onTap: () => _showLabelSheet(),
          ),
          Divider(height: 1, indent: 56, color: colors.outlineVariant),
          _SettingsTile(
            icon: Icons.music_note_outlined,
            title: 'Sound',
            trailing: Text(
              soundValue,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            showChevron: true,
            onTap: () => _showSoundSheet(),
          ),
          Divider(height: 1, indent: 56, color: colors.outlineVariant),
          _SettingsTile(
            icon: Icons.snooze_rounded,
            title: 'Snooze',
            trailing: IgnorePointer(
              child: Switch(
                value: _snooze,
                onChanged: (_) {},
                activeColor: AppTheme.brandOrange,
              ),
            ),
            showChevron: false,
            onTap: () => setState(() => _snooze = !_snooze),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissalChallenge(ColorScheme colors, TextTheme textTheme) {
    final String categoryLabel = _categories.isEmpty
        ? 'Random'
        : _categories.length == 1
        ? _categories.first
        : '${_categories.length} categories';

    final String strictnessLabel = switch (_difficulty) {
      Difficulty.easy => 'LENIENT',
      Difficulty.medium => 'MODERATE',
      Difficulty.hard => 'HIGH PRECISION',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: AppTheme.brandOrange),
              const SizedBox(width: 8),
              Text(
                'Dismissal Challenge',
                style: textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.brandOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.draw_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Draw Object',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You must draw this to stop the alarm',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _openCategoryPicker,
                      icon: Icon(
                        Icons.shuffle_rounded,
                        size: 14,
                        color: AppTheme.brandOrange,
                      ),
                      label: Text(
                        categoryLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.brandOrange,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: BorderSide(
                          color: AppTheme.brandOrange.withAlpha(150),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, indent: 56, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'AI Strictness',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        strictnessLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.brandOrange,
                  thumbColor: AppTheme.brandOrange,
                  inactiveTrackColor: colors.outlineVariant,
                  overlayColor: AppTheme.brandOrange.withAlpha(30),
                ),
                child: Slider(
                  value: _difficulty.index.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  onChanged: (double v) => setState(
                    () => _difficulty = Difficulty.values[v.round()],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Lenient',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Moderate',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Strict',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Setting higher strictness requires a more accurate drawing for the AI to accept it.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _testChallenge,
        icon: const Icon(Icons.draw_outlined, size: 18),
        label: const Text(
          'Test Drawing Challenge',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.brandOrange,
          side: BorderSide(color: AppTheme.brandOrange.withAlpha(180)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colors) {
    return Center(
      child: TextButton(
        onPressed: _deleteAlarm,
        child: Text(
          'Delete Alarm',
          style: TextStyle(
            color: colors.error,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLabelSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alarm Label',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Wake up for gym',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => Navigator.pop(sheetContext),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSoundSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alarm Sound',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SoundPicker(
                  selected: _sound,
                  onChanged: (String s) {
                    setState(() => _sound = s);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _TimeBox({
    required this.value,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.brandOrange.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Text(
        value,
        style: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
          fontSize: 40,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.brandOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
            ),
            trailing,
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
