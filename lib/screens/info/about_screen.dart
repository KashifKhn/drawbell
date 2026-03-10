import 'package:flutter/material.dart';

import '../../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBanner(isDark: isDark, colors: colors),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoCard(
                  colors: colors,
                  textTheme: textTheme,
                  title: 'About DrawBell',
                  rows: const [
                    _InfoRow(
                      icon: Icons.info_outline,
                      label: 'Version',
                      value: '1.0.1',
                    ),
                    _InfoRow(
                      icon: Icons.android_rounded,
                      label: 'Platform',
                      value: 'Android',
                    ),
                    _InfoRow(
                      icon: Icons.language_outlined,
                      label: 'Website',
                      value: 'drawbell.kashifkhan.dev',
                    ),
                    _InfoRow(
                      icon: Icons.lock_outline,
                      label: 'Privacy',
                      value: 'No cloud · no accounts',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  colors: colors,
                  textTheme: textTheme,
                  title: 'How it works',
                  rows: const [
                    _InfoRow(
                      icon: Icons.alarm_add_outlined,
                      label: 'Set an alarm',
                      value: 'Pick time & difficulty',
                    ),
                    _InfoRow(
                      icon: Icons.notifications_active_outlined,
                      label: 'Alarm rings',
                      value: 'A random doodle is chosen',
                    ),
                    _InfoRow(
                      icon: Icons.draw_rounded,
                      label: 'Draw the doodle',
                      value: 'On-device AI checks it',
                    ),
                    _InfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Alarm dismissed',
                      value: 'Once the AI recognises it',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DescriptionCard(
                  colors: colors,
                  textTheme: textTheme,
                  text:
                      'DrawBell is an alarm app with a twist — the only way to '
                      'dismiss it is to draw a doodle that an on-device AI '
                      'recognises. No cloud. No accounts. No data leaves your '
                      'device.',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final ColorScheme colors;

  const _HeroBanner({required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A1210), const Color(0xFF1A0A08)]
              : [
                  AppTheme.brandOrange.withAlpha(20),
                  AppTheme.brandOrange.withAlpha(8),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandOrange.withAlpha(isDark ? 18 : 12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandOrange.withAlpha(isDark ? 12 : 8),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandOrange.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.draw_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'DrawBell',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Draw to dismiss. Wake up your brain.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
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

class _InfoCard extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.colors,
    required this.textTheme,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Column(
            children: rows.asMap().entries.map((MapEntry<int, _InfoRow> e) {
              final bool isLast = e.key == rows.length - 1;
              return Column(
                children: [
                  _RowItem(row: e.value, colors: colors, textTheme: textTheme),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: colors.outlineVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _RowItem extends StatelessWidget {
  final _InfoRow row;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _RowItem({
    required this.row,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(row.icon, size: 20, color: AppTheme.brandOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              row.label,
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            ),
          ),
          Text(
            row.value,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final String text;

  const _DescriptionCard({
    required this.colors,
    required this.textTheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: AppTheme.brandOrange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
