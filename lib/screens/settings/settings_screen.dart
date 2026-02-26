import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SectionHeader(title: 'TEST', textTheme: textTheme, colors: colors),
          const SizedBox(height: 8),
          Card(
            child: _SettingsTile(
              icon: Icons.play_arrow_rounded,
              title: 'Test Alarm',
              subtitle: 'Try the drawing challenge now',
              showChevron: true,
              onTap: () => _showTestDifficultyPicker(context),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'ABOUT', textTheme: textTheme, colors: colors),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'DrawBell',
                  subtitle: 'Version 1.0.0',
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                const _SettingsTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Model',
                  subtitle: 'SE-ResNet, 345 categories, 76% accuracy',
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                const _SettingsTile(
                  icon: Icons.brush_outlined,
                  title: 'Dataset',
                  subtitle: 'Google Quick Draw',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTestDifficultyPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Difficulty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...Difficulty.values.map(
                  (Difficulty d) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(
                      Icons.speed_outlined,
                      color: AppTheme.brandOrange,
                    ),
                    title: Text(d.label),
                    subtitle: Text(
                      'Threshold: ${(d.threshold * 100).toInt()}%',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(
                        '/alarm/ring',
                        extra: <String, dynamic>{'difficulty': d},
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final TextTheme textTheme;
  final ColorScheme colors;

  const _SectionHeader({
    required this.title,
    required this.textTheme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.brandOrange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, color: colors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
