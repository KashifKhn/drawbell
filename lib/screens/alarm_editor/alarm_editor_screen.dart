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
import 'widgets/difficulty_selector.dart';
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'Set New Alarm'),
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildTimePicker(colors, textTheme),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _buildTimeUntilText(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingsGroup(colors, textTheme),
                const SizedBox(height: 16),
                _buildSoundGroup(colors, textTheme),
                const SizedBox(height: 16),
                _buildDifficultySection(colors, textTheme),
                const SizedBox(height: 16),
                _buildCategoriesSection(colors, textTheme),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildSaveButton(colors),
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

  String _buildTimeUntilText() {
    return formatTimeUntilAlarm(_time, _repeatDays);
  }

  Widget _buildSettingsGroup(ColorScheme colors, TextTheme textTheme) {
    final String categoryLabel = _categories.isEmpty
        ? 'Random'
        : _categories.length == 1
        ? _categories.first
        : '${_categories.length} selected';

    return Card(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.calendar_today_outlined,
            iconColor: AppTheme.brandOrange,
            title: 'Repeat',
            trailing: Text(
              formatDays(_repeatDays),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            showChevron: true,
            onTap: () => _showDayPickerSheet(colors),
          ),
          Divider(height: 1, indent: 52, color: colors.outlineVariant),
          _SettingsTile(
            icon: Icons.label_outline,
            iconColor: AppTheme.brandOrange,
            title: 'Label',
            trailing: Text(
              _labelController.text.isEmpty ? 'None' : _labelController.text,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            showChevron: true,
            onTap: () => _showLabelSheet(colors),
          ),
          Divider(height: 1, indent: 52, color: colors.outlineVariant),
          _SettingsTile(
            icon: Icons.category_outlined,
            iconColor: AppTheme.brandOrange,
            title: 'Categories',
            trailing: Text(
              categoryLabel,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            showChevron: true,
            onTap: _openCategoryPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundGroup(ColorScheme colors, TextTheme textTheme) {
    return Card(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.music_note_outlined,
            iconColor: AppTheme.brandOrange,
            title: 'Sound',
            trailing: Text(
              AlarmSound.fromKey(_sound).label,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            showChevron: true,
            onTap: () => _showSoundSheet(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DRAWING DIFFICULTY',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Complexity of the doodle required to dismiss.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withAlpha(150),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        DifficultySelector(
          selected: _difficulty,
          onChanged: (Difficulty d) {
            setState(() => _difficulty = d);
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ColorScheme colors, TextTheme textTheme) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SELECTED CATEGORIES',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _categories.take(10).map((String cat) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.brandOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.brandOrange.withAlpha(60)),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.brandOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        if (_categories.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '+${_categories.length - 10} more',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(ColorScheme colors) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 20),
            label: const Text(
              'Save Alarm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDayPickerSheet(ColorScheme colors) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repeat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DaySelector(
                      selectedDays: _repeatDays,
                      onChanged: (List<int> days) {
                        setState(() => _repeatDays = days);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
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
      },
    );
  }

  void _showLabelSheet(ColorScheme colors) {
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

  void _showSoundSheet(ColorScheme colors) {
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
  final Color iconColor;
  final String title;
  final Widget trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
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
