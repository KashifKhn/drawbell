import 'package:flutter/material.dart';

class AttemptCounter extends StatelessWidget {
  final int attempts;

  const AttemptCounter({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 20,
      child: attempts == 0
          ? null
          : Text(
              'Attempt $attempts',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withAlpha(150),
              ),
            ),
    );
  }
}
