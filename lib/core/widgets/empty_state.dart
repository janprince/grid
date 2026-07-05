import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Zero-data view: soft icon medallion, a short invitation to act,
/// and one clear CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Insets.xxxl,
          vertical: compact ? Insets.xxl : Insets.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.tealSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.teal),
            ),
            Gaps.xl,
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Gaps.sm,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              Gaps.xxl,
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
