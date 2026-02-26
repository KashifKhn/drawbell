import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'Test', textTheme: textTheme),
          ListTile(
            leading: Icon(Icons.play_arrow_rounded, color: colors.primary),
            title: const Text('Test Alarm'),
            subtitle: const Text('Try the drawing challenge now'),
            onTap: () => _showTestDifficultyPicker(context),
          ),
          const Divider(),
          _SectionHeader(title: 'Stats', textTheme: textTheme),
          ListTile(
            leading: Icon(Icons.bar_chart_rounded, color: colors.primary),
            title: const Text('Drawing Stats'),
            subtitle: const Text('Dismissals, attempts, categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stats'),
          ),
          const Divider(),
          _SectionHeader(title: 'About', textTheme: textTheme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('DrawBell'),
            subtitle: const Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Model'),
            subtitle: const Text('SE-ResNet, 345 categories, 76% accuracy'),
          ),
          ListTile(
            leading: const Icon(Icons.brush_outlined),
            title: const Text('Dataset'),
            subtitle: const Text('Google Quick Draw'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Difficulty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...Difficulty.values.map(
                (Difficulty d) => ListTile(
                  title: Text(d.label),
                  subtitle: Text('Threshold: ${(d.threshold * 100).toInt()}%'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/alarm/ring', extra: d);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final TextTheme textTheme;

  const _SectionHeader({required this.title, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
