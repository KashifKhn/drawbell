import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/classifier_service.dart';
import '../../services/imported_sound_service.dart';
import '../../services/ringtone_service.dart';
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
  DateTime? _scheduledDate;
  List<String> _allLabels = [];
  Map<String, String> _ringtoneLabels = {};

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
    _difficulty =
        existing?.difficulty ?? ref.read(settingsProvider).defaultDifficulty;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _categories = List<String>.from(existing?.categories ?? []);
    _sound = existing?.sound ?? ref.read(settingsProvider).defaultSoundKey;
    _snooze =
        existing?.snooze ?? ref.read(settingsProvider).defaultSnoozeEnabled;
    _scheduledDate = existing?.scheduledDate;
    _loadLabels();
    _loadRingtoneLabels();
  }

  Future<void> _loadLabels() async {
    final List<String> labels = await ClassifierService.loadLabels();
    if (mounted) setState(() => _allLabels = labels);
  }

  Future<void> _loadRingtoneLabels() async {
    final List<RingtoneInfo> ringtones =
        await RingtoneService.getAlarmRingtones();
    if (mounted) {
      setState(
        () => _ringtoneLabels = {
          for (final RingtoneInfo r in ringtones) r.uri: r.title,
        },
      );
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
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
      scheduledDate: _scheduledDate,
    );

    if (_isEditing) {
      ref.read(alarmListProvider.notifier).updateAlarm(alarm);
    } else {
      ref.read(alarmListProvider.notifier).addAlarm(alarm);
    }

    final String message = formatTimeUntilAlarm(
      _time,
      _repeatDays,
      scheduledDate: _scheduledDate,
    );
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
        'isTestMode': true,
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
              formatTimeUntilAlarm(
                _time,
                _repeatDays,
                scheduledDate: _scheduledDate,
              ),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildScheduleDateSection(colors, textTheme),
          const SizedBox(height: 16),
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
    final bool isPm = _time.period == DayPeriod.pm;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TimeScrollColumn(
            itemCount: 12,
            initialValue: _time.hourOfPeriod,
            labelFor: (int i) => (i == 0 ? 12 : i).toString().padLeft(2, '0'),
            onChanged: (int i) {
              final bool pm = _time.period == DayPeriod.pm;
              setState(
                () => _time = TimeOfDay(
                  hour: i + (pm ? 12 : 0),
                  minute: _time.minute,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: 40,
              ),
            ),
          ),
          _TimeScrollColumn(
            itemCount: 60,
            initialValue: _time.minute,
            labelFor: (int i) => i.toString().padLeft(2, '0'),
            onChanged: (int i) {
              setState(() => _time = TimeOfDay(hour: _time.hour, minute: i));
            },
          ),
          const SizedBox(width: 12),
          _AmPmToggle(
            isPm: isPm,
            onChanged: (bool newIsPm) {
              final int h = _time.hourOfPeriod;
              setState(
                () => _time = TimeOfDay(
                  hour: h + (newIsPm ? 12 : 0),
                  minute: _time.minute,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDateSection(ColorScheme colors, TextTheme textTheme) {
    final bool hasDate = _scheduledDate != null;
    final String dateLabel = hasDate
        ? formatScheduledDate(_scheduledDate!)
        : 'No date set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Schedule Date',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: _SettingsTile(
            icon: Icons.calendar_today_rounded,
            title: 'Date',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: hasDate
                        ? AppTheme.brandOrange
                        : colors.onSurfaceVariant,
                    fontWeight: hasDate ? FontWeight.w600 : null,
                  ),
                ),
                if (hasDate) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() {
                      _scheduledDate = null;
                    }),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            showChevron: true,
            onTap: _pickScheduledDate,
          ),
        ),
        if (hasDate && _repeatDays.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              'Scheduled date overrides repeat days',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickScheduledDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (BuildContext ctx, Widget? child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(
              ctx,
            ).colorScheme.copyWith(primary: AppTheme.brandOrange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _scheduledDate = picked);
    }
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
    final String soundValue = ImportedSoundService.labelFor(
      _sound,
      ringtoneLabels: _ringtoneLabels,
    );

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
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alarm Sound',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SoundPicker(
                      selected: _sound,
                      onChanged: (String s) {
                        setState(() => _sound = s);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeScrollColumn extends StatefulWidget {
  final int itemCount;
  final int initialValue;
  final String Function(int) labelFor;
  final ValueChanged<int> onChanged;

  const _TimeScrollColumn({
    required this.itemCount,
    required this.initialValue,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  State<_TimeScrollColumn> createState() => _TimeScrollColumnState();
}

class _TimeScrollColumnState extends State<_TimeScrollColumn> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double itemExtent = 64.0;
    const double columnWidth = 88.0;

    return SizedBox(
      width: columnWidth,
      height: itemExtent * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: itemExtent,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.brandOrange.withAlpha(60),
                  width: 1.5,
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: itemExtent,
            diameterRatio: 100,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.35,
            onSelectedItemChanged: (int i) {
              final int n = widget.itemCount;
              widget.onChanged(((i % n) + n) % n);
            },
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List<Widget>.generate(
                widget.itemCount,
                (int i) => Center(
                  child: Text(
                    widget.labelFor(i),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool isPm;
  final ValueChanged<bool> onChanged;

  const _AmPmToggle({required this.isPm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AmPmChip(
          label: 'AM',
          isSelected: !isPm,
          onTap: () => onChanged(false),
        ),
        const SizedBox(height: 8),
        _AmPmChip(label: 'PM', isSelected: isPm, onTap: () => onChanged(true)),
      ],
    );
  }
}

class _AmPmChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmPmChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandOrange
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
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
