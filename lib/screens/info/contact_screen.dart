import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [
          _ContactHeader(colors: colors, textTheme: textTheme),
          const SizedBox(height: 24),
          _SectionLabel(
            label: 'REACH OUT',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ContactTile(
                  colors: colors,
                  textTheme: textTheme,
                  icon: Icons.language_outlined,
                  title: 'Website',
                  value: 'drawbell.kashifkhan.dev',
                  onTap: () => _copyToClipboard(
                    context,
                    'https://drawbell.kashifkhan.dev',
                    'Website URL copied',
                  ),
                  trailing: const _CopyBadge(),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ContactTile(
                  colors: colors,
                  textTheme: textTheme,
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  value: 'hi@kashifkhan.dev',
                  onTap: () => _copyToClipboard(
                    context,
                    'hi@kashifkhan.dev',
                    'Email address copied',
                  ),
                  trailing: const _CopyBadge(),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ContactTile(
                  colors: colors,
                  textTheme: textTheme,
                  icon: Icons.code_rounded,
                  title: 'GitHub',
                  value: 'github.com/KashifKhn/drawbell',
                  onTap: () => _copyToClipboard(
                    context,
                    'https://github.com/KashifKhn/drawbell',
                    'GitHub URL copied',
                  ),
                  trailing: const _CopyBadge(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            label: 'REPORT & FEEDBACK',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ContactTile(
                  colors: colors,
                  textTheme: textTheme,
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
                  value: 'Open an issue on GitHub',
                  onTap: () => _copyToClipboard(
                    context,
                    'https://github.com/KashifKhn/drawbell/issues/new?template=bug_report.yml',
                    'Bug report URL copied',
                  ),
                  trailing: const _CopyBadge(),
                ),
                Divider(height: 1, indent: 52, color: colors.outlineVariant),
                _ContactTile(
                  colors: colors,
                  textTheme: textTheme,
                  icon: Icons.star_outline_rounded,
                  title: 'Rate the App',
                  value: 'Leave a review on Google Play',
                  onTap: () => _showSnack(context, 'Thanks for your support!'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            label: 'DEVELOPER',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            child: _ContactTile(
              colors: colors,
              textTheme: textTheme,
              icon: Icons.person_outline_rounded,
              title: 'Kashif Khan',
              value: 'kashifkhan.dev',
              onTap: () => _copyToClipboard(
                context,
                'https://kashifkhan.dev',
                'Website URL copied',
              ),
              trailing: const _CopyBadge(),
            ),
          ),
          const SizedBox(height: 24),
          _ResponseNote(colors: colors, textTheme: textTheme),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _ContactHeader({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.brandOrange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandOrange.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.headset_mic_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We\'d love to hear from you',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Questions, bug reports, feature requests — all welcome.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _SectionLabel({
    required this.label,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ContactTile({
    required this.colors,
    required this.textTheme,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _CopyBadge extends StatelessWidget {
  const _CopyBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.copy_outlined, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Copy',
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseNote extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _ResponseNote({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.schedule_outlined, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'We typically respond within 2–4 business days. For bugs, '
            'opening a GitHub issue helps us track and fix them faster.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
