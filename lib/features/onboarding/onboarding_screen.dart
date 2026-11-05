import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/models.dart';
import '../../core/theme/service_art.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

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
    Icons.cleaning_services_rounded,
    'Book cleaning and laundry',
    'Vetted cleaners and laundries near you. You pay once the job is '
        'done.',
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
                        SizedBox(height: 200, child: _PageArt(index: i)),
                        Gaps.xxxl,
                        Text(
                          page.title,
                          style: AppText.headline,
                          textAlign: TextAlign.center,
                        ),
                        Gaps.lg,
                        Text(
                          page.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.muted,
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
                    color: i == _page ? AppColors.navy : AppColors.line,
                    borderRadius: Corners.pill,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: PrimaryButton(
                label: isLast ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small piece of the real product for each page, instead of an icon.
class _PageArt extends StatelessWidget {
  const _PageArt({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: switch (index) {
          0 => NavyPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POWER LEFT',
                  style: AppText.overline.copyWith(
                    color: AppColors.onNavyMuted,
                  ),
                ),
                Gaps.sm,
                Text(
                  '71 units',
                  style: AppText.amountXL.copyWith(color: Colors.white),
                ),
                Gaps.lg,
                const MeterBar(fraction: 0.62, caption: 'About 11 days left'),
              ],
            ),
          ),
          1 => Row(
            children: [
              for (final category in ServiceCategory.values) ...[
                Expanded(
                  child: TintCard(
                    tint: category.tint,
                    arc: category.arc,
                    padding: const EdgeInsets.all(Insets.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ServiceBadge(category: category, size: 40),
                        Gaps.xl,
                        Text(
                          category.label,
                          maxLines: 2,
                          style: AppText.subtitle,
                        ),
                      ],
                    ),
                  ),
                ),
                if (category != ServiceCategory.values.last) Gaps.md,
              ],
            ],
          ),
          _ => const DetailGroup(
            rows: [
              DetailRow(label: 'My Home', value: 'ECG · Water · DStv'),
              DetailRow(label: "Mum's House", value: 'ECG · Water'),
              DetailRow(label: 'Tenant Apartment', value: 'ECG'),
            ],
          ),
        },
      ),
    ),
  );
}
