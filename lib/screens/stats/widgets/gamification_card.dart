import 'package:flutter/material.dart';

import '../../../models/dismissal_record.dart';
import '../../../theme.dart';

class GamificationCard extends StatelessWidget {
  final List<DismissalRecord> allStats;

  const GamificationCard({super.key, required this.allStats});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final int totalDismissals = allStats.length;
    final int uniqueCategories = allStats
        .map((DismissalRecord r) => r.category)
        .toSet()
        .length;

    final List<_Achievement> achievements = _getAchievements(
      totalDismissals,
      uniqueCategories,
    );

    final int xp = _calculateXP();
    final int level = _calculateLevel(xp);
    final int xpForCurrentLevel = _xpForLevel(level);
    final int xpForNextLevel = _xpForLevel(level + 1);
    final double levelProgress =
        (xp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppTheme.brandOrange),
                      const SizedBox(width: 4),
                      Text(
                        'Level $level',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.brandOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: levelProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: colors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.brandOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$xp / $xpForNextLevel XP',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final _Achievement a in achievements)
                  _AchievementBadge(
                    achievement: a,
                    colors: colors,
                    textTheme: textTheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateXP() {
    int xp = 0;
    for (final DismissalRecord r in allStats) {
      xp += 10;
      if (r.attempts == 0) xp += 5;
      if (r.confidence > 0.8) xp += 3;
      if (r.durationSeconds > 0 && r.durationSeconds < 15) xp += 5;
    }
    return xp;
  }

  int _calculateLevel(int xp) {
    int level = 1;
    while (_xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  int _xpForLevel(int level) {
    return (level - 1) * (level - 1) * 50;
  }

  List<_Achievement> _getAchievements(int total, int uniqueCategories) {
    final List<_Achievement> list = [];

    if (total >= 1) {
      list.add(
        _Achievement(icon: Icons.alarm, label: 'First Wake', unlocked: true),
      );
    } else {
      list.add(
        _Achievement(icon: Icons.alarm, label: 'First Wake', unlocked: false),
      );
    }

    if (total >= 7) {
      list.add(
        _Achievement(
          icon: Icons.calendar_today,
          label: 'Week Warrior',
          unlocked: true,
        ),
      );
    } else {
      list.add(
        _Achievement(
          icon: Icons.calendar_today,
          label: 'Week Warrior',
          unlocked: false,
          progress: '$total/7',
        ),
      );
    }

    if (total >= 30) {
      list.add(
        _Achievement(
          icon: Icons.emoji_events,
          label: 'Month Master',
          unlocked: true,
        ),
      );
    } else {
      list.add(
        _Achievement(
          icon: Icons.emoji_events,
          label: 'Month Master',
          unlocked: false,
          progress: '$total/30',
        ),
      );
    }

    if (uniqueCategories >= 10) {
      list.add(
        _Achievement(icon: Icons.palette, label: 'Artist', unlocked: true),
      );
    } else {
      list.add(
        _Achievement(
          icon: Icons.palette,
          label: 'Artist',
          unlocked: false,
          progress: '$uniqueCategories/10',
        ),
      );
    }

    if (total >= 100) {
      list.add(
        _Achievement(icon: Icons.diamond, label: 'Centurion', unlocked: true),
      );
    } else {
      list.add(
        _Achievement(
          icon: Icons.diamond,
          label: 'Centurion',
          unlocked: false,
          progress: '$total/100',
        ),
      );
    }

    final int firstTryCount = allStats
        .where((DismissalRecord r) => r.attempts == 0)
        .length;
    if (firstTryCount >= 10) {
      list.add(
        _Achievement(icon: Icons.bolt, label: 'Sharpshooter', unlocked: true),
      );
    } else {
      list.add(
        _Achievement(
          icon: Icons.bolt,
          label: 'Sharpshooter',
          unlocked: false,
          progress: '$firstTryCount/10',
        ),
      );
    }

    return list;
  }
}

class _Achievement {
  final IconData icon;
  final String label;
  final bool unlocked;
  final String? progress;

  const _Achievement({
    required this.icon,
    required this.label,
    required this.unlocked,
    this.progress,
  });
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _AchievementBadge({
    required this.achievement,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = achievement.unlocked
        ? AppTheme.brandOrange
        : colors.onSurfaceVariant.withAlpha(60);

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? AppTheme.brandOrange.withAlpha(20)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.unlocked
              ? AppTheme.brandOrange.withAlpha(50)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(achievement.icon, size: 24, color: badgeColor),
          const SizedBox(height: 4),
          Text(
            achievement.label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: achievement.unlocked
                  ? colors.onSurface
                  : colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
          if (achievement.progress != null) ...[
            const SizedBox(height: 2),
            Text(
              achievement.progress!,
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
