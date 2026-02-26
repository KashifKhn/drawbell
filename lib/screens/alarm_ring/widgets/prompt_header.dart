import 'package:flutter/material.dart';

class PromptHeader extends StatelessWidget {
  final String category;

  const PromptHeader({super.key, required this.category});

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
        ),
      ],
    );
  }
}
