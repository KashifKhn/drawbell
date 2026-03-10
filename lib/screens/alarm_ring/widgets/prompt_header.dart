import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants.dart';

class PromptHeader extends StatelessWidget {
  final String category;
  final VoidCallback? onChangeDoodle;
  final VoidCallback? onToggleHint;
  final HintMode hintMode;

  const PromptHeader({
    super.key,
    required this.category,
    this.onChangeDoodle,
    this.onToggleHint,
    this.hintMode = HintMode.none,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          'Draw a',
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          category,
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (onChangeDoodle != null || onToggleHint != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onChangeDoodle != null)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onChangeDoodle!();
                  },
                  icon: Icon(
                    Icons.shuffle_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: 'Change doodle',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (onToggleHint != null)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onToggleHint!();
                  },
                  icon: Icon(
                    _iconFor(hintMode),
                    size: 20,
                    color: hintMode == HintMode.none
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                  tooltip: _tooltipFor(hintMode),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static IconData _iconFor(HintMode mode) => switch (mode) {
    HintMode.none => Icons.lightbulb_outline_rounded,
    HintMode.thumbnail => Icons.lightbulb_rounded,
    HintMode.trace => Icons.gesture_rounded,
  };

  static String _tooltipFor(HintMode mode) => switch (mode) {
    HintMode.none => 'Show hint',
    HintMode.thumbnail => 'Switch to trace',
    HintMode.trace => 'Hide hint',
  };
}
