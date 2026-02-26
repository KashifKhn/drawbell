import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class DifficultySelector extends StatelessWidget {
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Difficulty>(
      segments: Difficulty.values
          .map(
            (Difficulty d) =>
                ButtonSegment<Difficulty>(value: d, label: Text(d.label)),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (Set<Difficulty> s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
