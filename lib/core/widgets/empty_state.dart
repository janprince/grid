import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'system.dart';

/// Zero-data view: soft icon tile, a short invitation to act,
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 32, color: AppColors.navy),
            ),
            Gaps.xl,
            Text(
              title,
              style: AppText.heading.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            Gaps.sm,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              Gaps.xxl,
              PrimaryButton(
                label: actionLabel!,
                icon: Icons.add_rounded,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
