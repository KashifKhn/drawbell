import 'package:flutter/material.dart';

import '../../../theme.dart';

class PredictionTile extends StatelessWidget {
  final int rank;
  final String label;
  final double score;
  final String? targetCategory;

  const PredictionTile({
    super.key,
    required this.rank,
    required this.label,
    required this.score,
    this.targetCategory,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isTop = rank == 1;
    final bool isTarget =
        targetCategory != null &&
        label.toLowerCase() == targetCategory!.toLowerCase();
    final String pct = (score * 100).toStringAsFixed(1);

    final Color badgeColor = isTarget
        ? const Color(0xFF4CAF50)
        : isTop
        ? AppTheme.brandOrange
        : colors.surfaceContainer;

    final Color barColor = isTarget
        ? const Color(0xFF4CAF50)
        : isTop
        ? AppTheme.brandOrange
        : colors.onSurfaceVariant.withAlpha(80);

    final Color labelColor = isTarget
        ? const Color(0xFF4CAF50)
        : isTop
        ? AppTheme.brandOrange
        : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isTop || isTarget
                    ? Colors.white
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: labelColor,
                                fontWeight: isTop || isTarget
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: isTop ? 15 : 13,
                              ),
                            ),
                          ),
                          if (isTarget) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: const Color(0xFF4CAF50),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: textTheme.bodySmall?.copyWith(
                        color: isTop || isTarget
                            ? labelColor
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.clamp(0.0, 1.0),
                    backgroundColor: colors.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: isTop ? 7 : 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
