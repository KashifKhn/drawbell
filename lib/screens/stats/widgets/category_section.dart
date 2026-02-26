import 'package:flutter/material.dart';

import '../../../theme.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<MapEntry<String, double>> entries;
  final bool isHardest;

  const CategorySection({
    super.key,
    required this.title,
    required this.entries,
    this.isHardest = true,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) Divider(height: 20, color: colors.outlineVariant),
                  _CategoryRow(
                    category: entries[i].key,
                    accuracy: entries[i].value,
                    isHardest: isHardest,
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double accuracy;
  final bool isHardest;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _CategoryRow({
    required this.category,
    required this.accuracy,
    required this.isHardest,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final double normalizedAccuracy = (1.0 / (accuracy + 1)).clamp(0.0, 1.0);
    final int accuracyPct = (normalizedAccuracy * 100).toInt();

    final Color barColor = isHardest
        ? colors.error.withAlpha(180)
        : const Color(0xFF4CAF50);

    final Color accuracyTextColor = isHardest
        ? colors.error
        : const Color(0xFF4CAF50);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.brandOrange.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(category),
            size: 18,
            color: AppTheme.brandOrange,
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
                  Text(
                    category,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$accuracyPct% Accuracy',
                    style: textTheme.labelSmall?.copyWith(
                      color: accuracyTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: normalizedAccuracy,
                  minHeight: 5,
                  backgroundColor: colors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final String lower = category.toLowerCase();
    if (lower.contains('cat')) return Icons.pets;
    if (lower.contains('dog')) return Icons.pets;
    if (lower.contains('car')) return Icons.directions_car;
    if (lower.contains('bicycle')) return Icons.pedal_bike;
    if (lower.contains('house')) return Icons.house;
    if (lower.contains('tree')) return Icons.park;
    if (lower.contains('flower')) return Icons.local_florist;
    if (lower.contains('sun')) return Icons.wb_sunny;
    if (lower.contains('star')) return Icons.star;
    if (lower.contains('fish')) return Icons.set_meal;
    if (lower.contains('bird')) return Icons.flutter_dash;
    if (lower.contains('clock')) return Icons.access_time;
    if (lower.contains('book')) return Icons.menu_book;
    if (lower.contains('phone')) return Icons.phone_android;
    if (lower.contains('guitar')) return Icons.music_note;
    if (lower.contains('piano')) return Icons.piano;
    return Icons.brush;
  }
}
