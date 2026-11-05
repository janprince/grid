import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'system.dart';
import '../theme/app_theme.dart';

/// Scaffold for multi-step flows (payments, service booking).
///
/// The step question now lives in the body as a large left-aligned heading —
/// the caller already renders it — so the app bar carries only context and
/// position. Progress is segmented rather than a continuous
/// `LinearProgressIndicator`, echoing MeterBar: measurement in discrete
/// units is GRID's visual language.
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
    this.totalLabel,
    this.totalValue,
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

  /// The primary action. Shrink-wraps beside the running total when
  /// [totalValue] is set, otherwise fills the bar.
  final Widget? bottomBar;

  /// Running total shown beside the action, so the amount being committed
  /// to stays visible at the moment of commitment.
  final String? totalLabel;
  final String? totalValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHeader(
                title: title,
                subtitle: subtitle == null
                    ? 'Step ${step + 1} of $stepCount'
                    : '$subtitle · Step ${step + 1} of $stepCount',
                onBack: onBack,
                divider: false,
              ),
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  6,
                  Insets.xl,
                  Insets.md,
                ),
                child: _StepSegments(step: step, stepCount: stepCount),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
        body: child,
        bottomNavigationBar: bottomBar == null
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.line, width: 1),
                  ),
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    Insets.xl,
                    Insets.md,
                    Insets.xl,
                    Insets.md,
                  ),
                  child: totalValue == null
                      ? bottomBar!
                      : Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  totalLabel ?? 'Total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.faint,
                                  ),
                                ),
                                Text(
                                  totalValue!,
                                  style: AppText.amount.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                            Gaps.lg,
                            Expanded(child: bottomBar!),
                          ],
                        ),
                ),
              ),
      ),
    );
  }
}

/// One segment per step — filled behind you, hollow ahead.
class _StepSegments extends StatelessWidget {
  const _StepSegments({required this.step, required this.stepCount});

  final int step;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Row(
        children: [
          for (var i = 0; i < stepCount; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.navy : AppColors.surfaceSubtle,
                  borderRadius: Corners.pill,
                ),
              ),
            ),
            if (i != stepCount - 1) const SizedBox(width: 4),
          ],
        ],
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
