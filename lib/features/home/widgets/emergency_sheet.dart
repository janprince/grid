import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../services/booking_flow_screen.dart';

/// Urgent-help entry point: jump straight into an emergency booking for
/// the categories where minutes matter.
Future<void> showEmergencySheet(BuildContext context) {
  return showAppBottomSheet(
    context,
    title: 'Emergency help',
    child: const _EmergencyOptions(),
  );
}

class _EmergencyOptions extends StatelessWidget {
  const _EmergencyOptions();

  static const _categories = [
    ServiceCategory.plumbing,
    ServiceCategory.electrical,
    ServiceCategory.powerBackup,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'A vetted professional is dispatched as fast as possible. '
          'An emergency call-out fee applies.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        Gaps.lg,
        for (final category in _categories) ...[
          AppCard(
            padding: const EdgeInsets.all(Insets.lg),
            onTap: () {
              Navigator.of(context).pop();
              context.push(
                Routes.bookService,
                extra: BookingArgs(
                  category: category,
                  urgency: ServiceUrgency.emergency,
                ),
              );
            },
            child: Row(
              children: [
                TintedIcon.danger(category.icon),
                Gaps.md,
                Expanded(
                  child: Text(
                    '${category.label} emergency',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
          Gaps.md,
        ],
        const InfoBanner(
          message:
              'Demo — no real dispatch happens yet. In the live app '
              'this alerts our on-call team immediately.',
        ),
      ],
    );
  }
}
