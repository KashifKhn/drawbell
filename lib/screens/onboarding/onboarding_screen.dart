import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/alarm_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await ref.read(storageServiceProvider).setOnboardingComplete();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _OnboardingPage(
                    icon: Icons.alarm_rounded,
                    iconColor: colors.primary,
                    title: 'Wake up with DrawBell',
                    description:
                        'Set alarms like any other app. Choose your '
                        'time, repeat days, and difficulty level.',
                    textTheme: textTheme,
                    colors: colors,
                  ),
                  _OnboardingPage(
                    icon: Icons.brush_rounded,
                    iconColor: colors.primary,
                    title: 'Draw to dismiss',
                    description:
                        'When your alarm rings, you must draw a '
                        'specific doodle to turn it off. No snoozing '
                        'your way out!',
                    textTheme: textTheme,
                    colors: colors,
                  ),
                  _OnboardingPage(
                    icon: Icons.smart_toy_rounded,
                    iconColor: colors.primary,
                    title: 'AI checks your drawing',
                    description:
                        'An on-device AI model recognizes 345 '
                        'categories. It runs locally — no internet '
                        'needed. Draw well enough and the alarm stops.',
                    textTheme: textTheme,
                    colors: colors,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_pageCount, (int i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? colors.primary
                              : colors.primary.withAlpha(60),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _currentPage == _pageCount - 1 ? 'Get started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final TextTheme textTheme;
  final ColorScheme colors;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.textTheme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withAlpha(180),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
