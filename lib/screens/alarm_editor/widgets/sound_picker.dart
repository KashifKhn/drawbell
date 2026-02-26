import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class SoundPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const SoundPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      children: AlarmSound.values.map((AlarmSound sound) {
        final bool isSelected = sound.key == selected;
        return ChoiceChip(
          label: Text(sound.label),
          selected: isSelected,
          onSelected: (_) => onChanged(sound.key),
          selectedColor: colors.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        );
      }).toList(),
    );
  }
}
