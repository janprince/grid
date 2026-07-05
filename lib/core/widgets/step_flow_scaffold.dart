import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Scaffold for multi-step flows (payments, service booking): title,
/// step progress bar, back handling that walks steps before popping,
/// and a pinned bottom CTA.
class StepFlowScaffold extends StatelessWidget {
  const StepFlowScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.stepCount,
    required this.child,
    required this.onBack,
    this.bottomBar,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  /// 0-based current step.
  final int step;
  final int stepCount;
  final Widget child;

  /// Called for the app-bar back button and system back. Should return
  /// to the previous step, or pop the route on the first step.
  final VoidCallback onBack;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
            tooltip: 'Back',
          ),
          title: Column(
            children: [
              Text(title),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.inkFaint),
                ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
              child: ClipRRect(
                borderRadius: Corners.pill,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  tween: Tween(end: (step + 1) / stepCount),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceDim,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: child,
        bottomNavigationBar: bottomBar == null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.sm,
                  Insets.xl,
                  Insets.lg,
                ),
                child: bottomBar!,
              ),
      ),
    );
  }
}

/// Animated switcher used between flow steps.
class StepTransition extends StatelessWidget {
  const StepTransition({super.key, required this.stepKey, required this.child});

  final Object stepKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(stepKey), child: child),
    );
  }
}
