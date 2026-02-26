import 'package:flutter/material.dart';

class ResultFeedback extends StatelessWidget {
  final bool? isCorrect;

  const ResultFeedback({super.key, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: isCorrect == null
          ? const SizedBox(height: 48, key: ValueKey<String>('empty'))
          : _FeedbackChip(
              key: ValueKey<bool>(isCorrect!),
              isCorrect: isCorrect!,
            ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final bool isCorrect;

  const _FeedbackChip({super.key, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color bgColor = isCorrect
        ? Colors.green.shade100
        : colors.errorContainer;
    final Color fgColor = isCorrect
        ? Colors.green.shade800
        : colors.onErrorContainer;
    final IconData icon = isCorrect
        ? Icons.check_circle_rounded
        : Icons.refresh_rounded;
    final String text = isCorrect ? 'Correct!' : 'Try again';

    return Container(
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
