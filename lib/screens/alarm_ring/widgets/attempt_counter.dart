import 'package:flutter/material.dart';

class AttemptCounter extends StatelessWidget {
  final int attempts;

  const AttemptCounter({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts == 0) return const SizedBox.shrink();

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Text(
      'Attempt $attempts',
      style: TextStyle(fontSize: 14, color: colors.onSurface.withAlpha(150)),
    );
  }
}
