import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class _OnboardPage {
  const _OnboardPage(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;
}

const _pages = [
  _OnboardPage(
    Icons.bolt_rounded,
    'Pay utilities with ease',
    'Buy ECG credit, settle water bills and renew TV or internet in '
        'seconds — all from one place.',
  ),
  _OnboardPage(
    Icons.handyman_rounded,
    'Book trusted help',
    'Vetted plumbers, electricians and AC technicians for your home, '
        'with transparent call-out fees.',
  ),
  _OnboardPage(
    Icons.other_houses_rounded,
    'Keep your home organised',
    'Save your meters and accounts, track every payment, and never miss '
        'a renewal across all your homes.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).completeOnboarding();
    if (mounted) context.go(Routes.login);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(Insets.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.xxxl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: AppColors.forest,
                          ),
                        ),
                        Gaps.xxxl,
                        Text(
                          page.title,
                          style: theme.textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        Gaps.lg,
                        Text(
                          page.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.forestDeep
                        : AppColors.outline,
                    borderRadius: Corners.pill,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: FilledButton(
                onPressed: _next,
                child: Text(isLast ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
