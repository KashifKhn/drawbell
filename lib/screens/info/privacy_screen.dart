import 'package:flutter/material.dart';

import '../../theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _PrivacySummaryBanner(colors: colors, textTheme: textTheme),
          const SizedBox(height: 24),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.storage_outlined,
            title: 'Data We Store',
            body:
                'DrawBell stores the following data locally on your device only:\n\n'
                '• Alarm schedules and settings\n'
                '• App preferences (theme, difficulty, snooze duration)\n'
                '• Dismissal statistics (categories drawn, attempts, timestamps)\n\n'
                'This data is stored using Android\'s SharedPreferences and never '
                'leaves your device.',
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.block_outlined,
            title: 'Data We Do NOT Collect',
            body:
                'We do not collect, transmit, or store any of the following:\n\n'
                '• Your drawings or doodles\n'
                '• Location data\n'
                '• Device identifiers or advertising IDs\n'
                '• Analytics or usage telemetry\n'
                '• Crash reports (unless you manually share them)\n'
                '• Personal information of any kind\n\n'
                'DrawBell has no backend server and makes no network requests.',
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.smart_toy_outlined,
            title: 'On-Device AI',
            body:
                'All doodle recognition is performed entirely on your device '
                'using a TensorFlow Lite model bundled with the app. Your '
                'drawings are processed in memory and immediately discarded. '
                'No drawing data is ever written to disk or sent anywhere.',
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.notifications_outlined,
            title: 'Notifications & Permissions',
            body:
                'DrawBell requests the following permissions:\n\n'
                '• POST_NOTIFICATIONS — to deliver alarm notifications\n'
                '• SCHEDULE_EXACT_ALARM — to fire alarms at precise times\n'
                '• VIBRATE — to vibrate on alarm\n\n'
                'If you import a custom alarm sound, Android shows its own '
                'file picker so no media-storage permission is needed.\n\n'
                'No permission is used to collect or transmit data. All '
                'permissions are used solely for core alarm functionality.',
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.child_care_outlined,
            title: "Children's Privacy",
            body:
                "DrawBell does not knowingly collect any information from "
                "children under the age of 13. Because we collect no personal "
                "data at all, the app is safe for users of any age.",
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.update_outlined,
            title: 'Changes to This Policy',
            body:
                'If we make material changes to this Privacy Policy, we will '
                'update the "last updated" date and notify users via an in-app '
                'notice on the next launch. Continued use of the app after '
                'changes constitutes acceptance of the updated policy.',
          ),
          const SizedBox(height: 12),
          _PrivacySection(
            colors: colors,
            textTheme: textTheme,
            icon: Icons.mail_outline_rounded,
            title: 'Contact',
            body:
                'If you have any questions or concerns about this Privacy '
                'Policy, please use the Contact Us page in the app settings.',
          ),
          const SizedBox(height: 16),
          _LastUpdatedNote(colors: colors, textTheme: textTheme),
        ],
      ),
    );
  }
}

class _PrivacySummaryBanner extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _PrivacySummaryBanner({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandOrange.withAlpha(50), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy is fully protected',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.brandOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DrawBell collects no personal data. Everything stays '
                  'on your device. No accounts. No tracking. No cloud.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    height: 1.5,
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

class _PrivacySection extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final IconData icon;
  final String title;
  final String body;

  const _PrivacySection({
    required this.colors,
    required this.textTheme,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.brandOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastUpdatedNote extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _LastUpdatedNote({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Last updated: March 2026',
        style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
