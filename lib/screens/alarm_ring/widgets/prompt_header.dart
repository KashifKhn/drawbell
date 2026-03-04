import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromptHeader extends StatelessWidget {
  final String category;
  final VoidCallback? onChangeDoodle;

  const PromptHeader({super.key, required this.category, this.onChangeDoodle});

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
        if (onChangeDoodle != null) ...[
          const SizedBox(height: 8),
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
        ],
      ],
    );
  }
}
