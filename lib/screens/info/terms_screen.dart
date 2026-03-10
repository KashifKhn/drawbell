import 'package:flutter/material.dart';

import '../../theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _LastUpdatedBadge(colors: colors, textTheme: textTheme),
          const SizedBox(height: 24),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '1',
            title: 'Acceptance of Terms',
            body:
                'By downloading, installing, or using DrawBell ("the App"), you '
                'agree to be bound by these Terms of Service. If you do not agree '
                'to these terms, please uninstall and discontinue use of the App.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '2',
            title: 'Description of Service',
            body:
                'DrawBell is an alarm application that requires users to complete '
                'a doodle-drawing challenge verified by an on-device AI model in '
                'order to dismiss an alarm. The App operates entirely on your '
                'device and does not require an internet connection.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '3',
            title: 'No Warranty — Alarm Reliability',
            body:
                'DrawBell is provided "as is" and "as available" without any '
                'warranty of any kind. We do not guarantee that alarms will fire '
                'at the exact scheduled time on every device. Alarm delivery '
                'depends on your device\'s battery optimisation settings, '
                'Android version, and other system factors outside our control.\n\n'
                'YOU ASSUME ALL RISK related to using DrawBell as a wake-up '
                'alarm. We are not liable for missed appointments, late arrivals, '
                'or any other consequence of a missed or delayed alarm.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '4',
            title: 'Permitted Use',
            body:
                'You may use the App for personal, non-commercial purposes. You '
                'may not:\n\n'
                '• Reverse-engineer, decompile, or disassemble the App\n'
                '• Use the App for any unlawful purpose\n'
                '• Distribute, sell, or sublicense the App\n'
                '• Remove or alter any proprietary notices in the App',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '5',
            title: 'AI Model & Drawing Challenge',
            body:
                'The AI model used for doodle recognition is trained on the '
                'Google Quick Draw dataset and runs entirely on your device. '
                'Recognition accuracy is approximately 76% top-1. The App '
                'applies difficulty-based thresholds that may affect how '
                'strictly your drawing is judged. We make no guarantee that '
                'every drawing will be correctly recognised.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '6',
            title: 'Limitation of Liability',
            body:
                'To the fullest extent permitted by applicable law, DrawBell '
                'and its developers shall not be liable for any indirect, '
                'incidental, special, or consequential damages arising from '
                'your use or inability to use the App, including but not '
                'limited to missed alarms, lost data, or personal injury.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '7',
            title: 'Changes to Terms',
            body:
                'We reserve the right to modify these Terms at any time. '
                'Material changes will be communicated through an in-app notice '
                'or an update to this screen. Continued use of the App after '
                'changes are posted constitutes your acceptance of the new Terms.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '8',
            title: 'Governing Law',
            body:
                'These Terms shall be governed by and construed in accordance '
                'with applicable law. Any disputes arising under these Terms '
                'shall be subject to the exclusive jurisdiction of the '
                'competent courts.',
          ),
          const SizedBox(height: 12),
          _LegalSection(
            colors: colors,
            textTheme: textTheme,
            number: '9',
            title: 'Contact',
            body:
                'If you have any questions about these Terms, please reach out '
                'via the Contact Us page in the app settings.',
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedBadge extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _LastUpdatedBadge({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.brandOrange.withAlpha(24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.brandOrange.withAlpha(60),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(width: 6),
              Text(
                'Last updated: March 2026',
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.brandOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final String number;
  final String title;
  final String body;

  const _LegalSection({
    required this.colors,
    required this.textTheme,
    required this.number,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
            const SizedBox(height: 12),
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
