import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// The tone of an outcome screen. [pending] is for "it's with the biller":
/// not done, not failed.
enum OutcomeTone { success, failure, pending }

/// The shared shape of every "it's done" screen: a saturated ground
/// carrying the verdict, and a sheet rising over it with the detail.
///
/// Payment success already had this treatment and it was the best screen in
/// the app — but payment *failure* and booking confirmation each fell back
/// to a plain page with a coloured circle, so two thirds of the outcomes a
/// user can reach looked unfinished. One scaffold, three outcomes.
class OutcomeScaffold extends StatelessWidget {
  const OutcomeScaffold({
    super.key,
    required this.tone,
    required this.headline,
    required this.message,
    required this.content,
    this.figure,
    this.actions = const [],
  });

  final OutcomeTone tone;
  final String headline;
  final String message;

  /// The amount or reference the ground leads with, set large.
  final String? figure;

  /// Content of the sheet.
  final List<Widget> content;

  /// Pinned beneath the sheet content.
  final List<Widget> actions;

  Color get _ground => switch (tone) {
    OutcomeTone.success => AppColors.navy,
    OutcomeTone.failure => AppColors.dangerDeep,
    OutcomeTone.pending => AppColors.navyDeep,
  };

  Color get _accent => switch (tone) {
    OutcomeTone.success => AppColors.navySoft,
    OutcomeTone.failure => AppColors.dangerBg,
    OutcomeTone.pending => AppColors.amber,
  };

  IconData get _icon => switch (tone) {
    OutcomeTone.success => Icons.check_rounded,
    OutcomeTone.failure => Icons.close_rounded,
    OutcomeTone.pending => Icons.hourglass_top_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _ground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.xxl,
                Insets.xl,
                Insets.xxxl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, size: 34, color: _accent),
                  ),
                  Gaps.lg,
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (figure != null) ...[
                    Gaps.sm,
                    Text(
                      figure!,
                      style: theme.textTheme.displaySmall?.tabular.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                  Gaps.xs,
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                borderRadius: Corners.sheetTop,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Insets.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...content, ...actions],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
