import 'package:flutter/material.dart';

class ResultFeedback extends StatelessWidget {
  final bool? isCorrect;

  const ResultFeedback({super.key, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (isCorrect == null) {
      return const SizedBox(height: 48);
    }

    final Color bgColor = isCorrect!
        ? Colors.green.shade100
        : colors.errorContainer;
    final Color fgColor = isCorrect!
        ? Colors.green.shade800
        : colors.onErrorContainer;
    final IconData icon = isCorrect!
        ? Icons.check_circle_rounded
        : Icons.refresh_rounded;
    final String text = isCorrect! ? 'Correct!' : 'Try again';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
