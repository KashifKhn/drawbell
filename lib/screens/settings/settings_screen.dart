import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/imported_sound_service.dart';
import '../../theme.dart';
import '../alarm_editor/widgets/difficulty_selector.dart';
import '../alarm_editor/widgets/sound_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppSettings settings = ref.watch(settingsProvider);

    final String soundLabel = ImportedSoundService.labelFor(
      settings.defaultSoundKey,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SectionHeader(
            title: 'ALARM DEFAULTS',
            textTheme: textTheme,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Difficulty',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI strictness applied to new alarms',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DifficultySelector(
                    selected: settings.defaultDifficulty,
                    onChanged: (Difficulty d) => ref
                        .read(settingsProvider.notifier)
                        .setDefaultDifficulty(d),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.snooze_rounded,
                  title: 'Snooze by Default',
                  subtitle: 'New alarms will have snooze enabled',
                  value: settings.defaultSnoozeEnabled,
                  onChanged: (bool v) => ref
                      .read(settingsProvider.notifier)
                      .setDefaultSnoozeEnabled(v),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ActionTile(
                  icon: Icons.music_note_outlined,
                  title: 'Default Sound',
                  trailing: Text(
                    soundLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _showSoundSheet(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Snooze Duration',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${settings.snoozeMinutes} minutes',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Slider(
                    value: settings.snoozeMinutes.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 3,
                    label: '${settings.snoozeMinutes} min',
                    activeColor: AppTheme.brandOrange,
                    onChanged: (double v) => ref
                        .read(settingsProvider.notifier)
                        .setSnoozeMinutes(v.toInt()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '5 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '10 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '15 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '20 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'NOTIFICATIONS',
            textTheme: textTheme,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Card(
            child: _SwitchTile(
              icon: Icons.vibration_rounded,
              title: 'Vibration',
              subtitle: 'Vibrate when an alarm rings',
              value: settings.vibrationEnabled,
              onChanged: (bool v) =>
                  ref.read(settingsProvider.notifier).setVibrationEnabled(v),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'APPEARANCE',
            textTheme: textTheme,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.auto_mode_outlined, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined, size: 18),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (Set<ThemeMode> s) => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(s.first),
                    style: SegmentedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'TEST', textTheme: textTheme, colors: colors),
          const SizedBox(height: 8),
          Card(
            child: _ActionTile(
              icon: Icons.play_arrow_rounded,
              title: 'Test Alarm',
              subtitle: 'Try the drawing challenge now',
              showChevron: true,
              onTap: () => _showTestDifficultyPicker(context, settings),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'DATA', textTheme: textTheme, colors: colors),
          const SizedBox(height: 8),
          Card(
            child: _ActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear Statistics',
              subtitle: 'Remove all dismissal history and streaks',
              showChevron: false,
              destructive: true,
              onTap: () => _confirmClearStats(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'ABOUT', textTheme: textTheme, colors: colors),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.info_outline,
                  title: 'About DrawBell',
                  showChevron: true,
                  onTap: () => context.push('/about'),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ActionTile(
                  icon: Icons.gavel_outlined,
                  title: 'Terms of Service',
                  showChevron: true,
                  onTap: () => context.push('/terms'),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ActionTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  showChevron: true,
                  onTap: () => context.push('/privacy'),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ActionTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Contact Us',
                  showChevron: true,
                  onTap: () => context.push('/contact'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSoundSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Alarm Sound',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied to new alarms',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SoundPicker(
                      selected: settings.defaultSoundKey,
                      onChanged: (String s) {
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultSoundKey(s);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTestDifficultyPicker(BuildContext context, AppSettings settings) {
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
                      'Threshold: ${(d.threshold * 100).toInt()}%'
                      '${d.mercyAttempts != null ? ' · ${d.mercyAttempts} mercy attempts' : ''}',
                    ),
                    trailing: d == settings.defaultDifficulty
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppTheme.brandOrange,
                          )
                        : const Icon(Icons.chevron_right, size: 18),
                    selected: d == settings.defaultDifficulty,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(
                        '/alarm/ring',
                        extra: <String, dynamic>{
                          'difficulty': d,
                          'isTestMode': true,
                        },
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

  void _confirmClearStats(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear Statistics'),
        content: const Text(
          'This will permanently delete all dismissal history, streaks, and accuracy data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(dismissalStatsProvider.notifier).clearStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics cleared')),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
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

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onChanged(!value),
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.brandOrange,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color iconColor = destructive ? colors.error : AppTheme.brandOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: destructive ? colors.error : colors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
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
