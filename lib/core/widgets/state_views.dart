import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'system.dart';

/// Generic something-went-wrong view with a retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We could not load this right now. Please try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.danger,
              ),
            ),
            Gaps.xl,
            Text(title, style: theme.textTheme.headlineSmall),
            Gaps.sm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            if (onRetry != null) ...[
              Gaps.xxl,
              SecondaryButton(
                label: 'Try again',
                onPressed: onRetry,
                expand: false,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No-internet view.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: 'You are offline',
      message:
          'Check your internet connection, then try again. Your saved homes '
          'and accounts are still available.',
      onRetry: onRetry,
    );
  }
}
